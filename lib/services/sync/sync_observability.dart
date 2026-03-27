import '../../utils/app_logger.dart';

class SyncObservability {
  static final SyncObservability _instance = SyncObservability._internal();

  factory SyncObservability() {
    return _instance;
  }

  SyncObservability._internal();

  int syncSuccessCount = 0;
  int syncFailCount = 0;
  int pendingQueueSize = 0;

  void recordSyncSuccess() {
    syncSuccessCount++;
    AppLogger.i("[METRICS] sync_success_total=$syncSuccessCount");
  }

  void recordSyncFail() {
    syncFailCount++;
    AppLogger.i("[METRICS] sync_fail_total=$syncFailCount");
  }

  void recordPendingSize(int size) {
    pendingQueueSize = size;
    AppLogger.i("[METRICS] pending_queue_size=$size");
  }
}
