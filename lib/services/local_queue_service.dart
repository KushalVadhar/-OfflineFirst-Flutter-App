import 'package:hive/hive.dart';
import '../models/sync_queue_item.dart';

class LocalQueueService {
  final Box<SyncQueueItem> box;

  LocalQueueService(this.box);

  List<SyncQueueItem> getAll() {
    return box.values.toList();
  }

  Future<void> save(SyncQueueItem item) async {
    await box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  SyncQueueItem? getById(String id) {
    return box.get(id);
  }

  int get pendingCount => box.length;

  String? getIdForAction(String actionType, String entityId) {
    try {
      final item = box.values.firstWhere(
        (item) => item.actionType == actionType && item.entityId == entityId,
      );
      return item.id;
    } catch (_) {
      return null;
    }
  }

  bool existsForAction(String actionType, String entityId) {
    return getIdForAction(actionType, entityId) != null;
  }
}
