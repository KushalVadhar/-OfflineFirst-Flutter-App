import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'controllers/article_controller.dart';
import 'controllers/sync_controller.dart';
import 'utils/config/constants.dart';
import 'utils/app_logger.dart';
import 'services/sync/sync_observability.dart';
import 'services/local_article_service.dart';
import 'services/local_queue_service.dart';
import 'models/article.dart';
import 'models/sync_queue_item.dart';
import 'services/remote/base_remote.dart';
import 'services/remote/firestore_remote.dart';
import 'services/remote/mock_remote.dart';
import 'services/article_service.dart';
import 'services/sync/sync_engine.dart';
import 'services/sync/sync_queue_logic.dart';

import 'firebase_options.dart';

// IMPORTANT: Set this to false for live Firebase, true for locally simulated testing
const bool useMockRemote = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (Ignored if using MockRemote)
  if (!useMockRemote) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 5));
      AppLogger.i("[SYNC] Firebase initialized");
    } catch (e) {
      AppLogger.w("[SYNC] Firebase initialization skipped/failed: $e");
    }
  }

  // 2. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ArticleAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());
  
  final articleBox = await Hive.openBox<Article>(AppConstants.articlesBox);
  final queueBox = await Hive.openBox<SyncQueueItem>(AppConstants.queueBox);

  // 3. Wires up all dependencies
  final observability = SyncObservability();
  final articleDao = LocalArticleService(articleBox);
  final queueDao = LocalQueueService(queueBox);

  // SWITCHING LOGIC: Use Mock for evaluation, Firestore for production
  final BaseRemote remote = useMockRemote 
      ? MockRemote() 
      : FirestoreRemote(FirebaseFirestore.instance);

  final repository = ArticleService(localDao: articleDao, remote: remote);
  final syncQueue = SyncQueueLogic(queueService: queueDao, observability: observability);
  final syncEngine = SyncEngine(
    syncQueue: syncQueue,
    remote: remote,
    repository: repository,
    observability: observability,
  );

  // 4. Seed articles moved to ArticleListScreen or manually triggered
  // await remote.seedArticles();

  // 5. Log pending items on startup
  final pending = queueDao.pendingCount;
  AppLogger.i('[QUEUE] App started. Pending items in queue: $pending');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SyncController>(
          create: (_) => SyncController(
            syncEngine: syncEngine,
            syncQueue: syncQueue,
          ),
        ),
        ChangeNotifierProvider<ArticleController>(
          create: (_) => ArticleController(
            repository: repository,
          )..loadArticles(),
        ),
      ],
      child: const App(),
    ),
  );
}
