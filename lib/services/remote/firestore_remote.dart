import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_logger.dart';
import '../../models/article.dart';
import '../../models/sync_queue_item.dart';

import 'base_remote.dart';

class FirestoreRemote implements BaseRemote {
  final FirebaseFirestore firestore;

  FirestoreRemote(this.firestore);

  Future<List<Article>> fetchArticles({int limit = 10, int offset = 0}) async {
    try {
      final snapshot = await firestore.collection('articles').get()
          .timeout(const Duration(seconds: 4));
      final articles = snapshot.docs.map((doc) {
        return Article.fromFirestore(doc.data());
      }).toList();
      AppLogger.i("[SYNC] Fetched ${articles.length} articles from Firestore");
      return articles;
    } catch (e, stack) {
      AppLogger.e("[SYNC] Error fetching articles", e, stack);
      rethrow;
    }
  }

  Future<void> applyAction(SyncQueueItem item) async {
    try {
      // Step 1: Write to collection 'actions' (idempotent thanks to item.id)
      await firestore.collection('actions').doc(item.id).set({
        'actionType': item.actionType.toUpperCase(),
        'entityId': item.entityId,
        'payload': item.payload,
        'appliedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      // Step 2: Update the article document
      final articleRef = firestore.collection('articles').doc(item.entityId);
      final now = DateTime.now().toIso8601String();

      Map<String, dynamic> updates = {'version': now};
      
      final Map<String, dynamic> payloadMap = jsonDecode(item.payload);
      final action = item.actionType.toUpperCase();

      if (action == 'LIKE') {
        updates['isLiked'] = payloadMap['isLiked'];
      } else if (action == 'SAVE') {
        updates['isSaved'] = payloadMap['isSaved'];
      } else if (action == 'NOTE') {
        updates['note'] = payloadMap['note'];
      }

      await articleRef.update(updates);
      AppLogger.i("[SYNC] Applied action ${action} for article ${item.entityId}");
    } catch (e, stack) {
      AppLogger.e("[SYNC] Error applying action ${item.id}", e, stack);
      rethrow;
    }
  }

  Future<void> seedArticles() async {
    try {
      final List<Article> sampleArticles = [
        Article(
          id: '1',
          title: 'Understanding Flutter Architecture',
          body: 'Flutter uses a layered architecture...',
          cachedAt: DateTime.now(),
          version: DateTime.now().toIso8601String(),
        ),
        Article(
          id: '2',
          title: 'Mastering Hive Database',
          body: 'Hive is a lightweight and blazing fast key-value database...',
          cachedAt: DateTime.now(),
          version: DateTime.now().toIso8601String(),
        ),
        Article(
          id: '3',
          title: 'Firebase for Offline Apps',
          body: 'Firebase provides real-time database capabilities...',
          cachedAt: DateTime.now(),
          version: DateTime.now().toIso8601String(),
        ),
        Article(
          id: '4',
          title: 'Bloc State Management',
          body: 'Bloc helps separate presentation from business logic...',
          cachedAt: DateTime.now(),
          version: DateTime.now().toIso8601String(),
        ),
        Article(
          id: '5',
          title: 'Clean Code in Dart',
          body: 'Writing clean and maintainable code is essential...',
          cachedAt: DateTime.now(),
          version: DateTime.now().toIso8601String(),
        ),
      ];

      for (var article in sampleArticles) {
        await firestore.collection('articles').doc(article.id).set(article.toFirestore());
      }
      AppLogger.i("[SYNC] Seeded 5 articles to Firestore");
    } catch (e, stack) {
      AppLogger.e("[SYNC] Error seeding articles", e, stack);
    }
  }
}
