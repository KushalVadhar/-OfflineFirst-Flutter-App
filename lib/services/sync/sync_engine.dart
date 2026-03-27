import '../../utils/app_logger.dart';
import 'sync_observability.dart';
import '../../models/sync_queue_item.dart';
import '../remote/base_remote.dart';
import '../article_service.dart';
import 'idempotency_helper.dart';
import 'sync_queue_logic.dart';

class SyncEngine {
  final SyncQueueLogic syncQueue;
  final BaseRemote remote;
  final ArticleService repository;
  final SyncObservability observability;

  SyncEngine({
    required this.syncQueue,
    required this.remote,
    required this.repository,
    required this.observability,
  });

  bool _isSyncing = false;

  Future<void> processAll() async {
    // Step 1: Guard against concurrent runs
    if (_isSyncing) {
      AppLogger.w('[SYNC] Sync already in progress, skipping');
      return;
    }
    _isSyncing = true;

    try {
      // Step 2: Get pending items
      final items = syncQueue.getPendingItems();
      if (items.isEmpty) {
        AppLogger.i('[SYNC] No pending items to sync');
        _isSyncing = false;
        return;
      }
      AppLogger.i('[SYNC] Starting sync of ${items.length} items');

      // Step 3: Process each item
      for (var item in items) {
        await _processItem(item);
      }
    } finally {
      // Step 4: Done
      _isSyncing = false;
      AppLogger.i('[SYNC] Sync complete');
    }
  }

  Future<void> _processItem(SyncQueueItem item) async {
    // Step 1: Mark as processing
    await syncQueue.markProcessing(item);
    AppLogger.d('[SYNC] Processing: ${item.actionType} | ${item.id}');

    // Step 2: Try to apply to Firebase
    try {
      await remote.applyAction(item);
      await syncQueue.markSuccess(item);
      AppLogger.i('[SYNC] Success: ${item.actionType} for ${item.entityId}');
    } catch (e) {
      AppLogger.e('[SYNC] Failed: ${item.id} | error: $e');
      await syncQueue.markFailed(item);
    }
  }

  Future<void> enqueueAction({
    required String actionType,
    required String entityId,
    String payload = '{}',
  }) async {
    final item = SyncQueueItem(
      id: IdempotencyHelper.generateKey(),
      actionType: actionType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
      retryCount: 0,
      nextRetryAt: null,
      isProcessing: false,
    );
    await syncQueue.enqueue(item);
  }
}
