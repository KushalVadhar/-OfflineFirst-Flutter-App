import 'dart:math';
import '../../utils/config/constants.dart';
import '../../utils/app_logger.dart';
import 'sync_observability.dart';
import '../local_queue_service.dart';
import '../../models/sync_queue_item.dart';

class SyncQueueLogic {
  final LocalQueueService queueService;
  final SyncObservability observability;

  SyncQueueLogic({
    required this.queueService,
    required this.observability,
  });

  Future<void> enqueue(SyncQueueItem item) async {
    // Step 1: Replace existing action for the same entity and type (Last-write-wins in queue)
    final existingId = queueService.getIdForAction(item.actionType, item.entityId);
    if (existingId != null) {
      await queueService.delete(existingId);
      AppLogger.i('[QUEUE] Replacing existing ${item.actionType} for ${item.entityId}');
    }

    // Step 2: Save to Hive
    await queueService.save(item);

    // Step 3: Log and update metrics
    AppLogger.i('[QUEUE] Enqueued: ${item.actionType} for ${item.entityId} | id: ${item.id}');
    observability.recordPendingSize(queueService.pendingCount);
  }

  List<SyncQueueItem> getPendingItems() {
    final now = DateTime.now();
    final items = queueService.getAll().where((item) {
      final notProcessing = !item.isProcessing;
      final readyForRetry = item.nextRetryAt == null || item.nextRetryAt!.isBefore(now);
      return notProcessing && readyForRetry;
    }).toList();

    AppLogger.i('[QUEUE] ${items.length} items ready for sync');
    return items;
  }

  Future<void> markProcessing(SyncQueueItem item) async {
    item.isProcessing = true;
    await queueService.save(item);
  }

  Future<void> markSuccess(SyncQueueItem item) async {
    await queueService.delete(item.id);
    AppLogger.i('[QUEUE] Removed after success: ${item.id}');
    observability.recordSyncSuccess();
    observability.recordPendingSize(queueService.pendingCount);
  }

  Future<void> markFailed(SyncQueueItem item) async {
    item.isProcessing = false;
    item.retryCount++;

    if (item.retryCount >= AppConstants.maxRetries) {
      await queueService.delete(item.id);
      AppLogger.e('[QUEUE] Max retries reached, dropping: ${item.id}');
      observability.recordSyncFail();
      observability.recordPendingSize(queueService.pendingCount);
    } else {
      final delaySeconds = AppConstants.baseBackoff.inSeconds * pow(2, item.retryCount - 1).toInt();
      item.nextRetryAt = DateTime.now().add(Duration(seconds: delaySeconds));
      await queueService.save(item);
      AppLogger.w('[QUEUE] Retry ${item.retryCount}/${AppConstants.maxRetries} scheduled in ${delaySeconds}s for: ${item.id}');
    }
  }

  int get pendingCount => queueService.pendingCount;
}
