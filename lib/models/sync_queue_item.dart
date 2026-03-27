import 'package:hive/hive.dart';

part 'sync_queue_item.g.dart';

@HiveType(typeId: 1)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String actionType;

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final String payload;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  DateTime? nextRetryAt;

  @HiveField(7)
  bool isProcessing;

  SyncQueueItem({
    required this.id,
    required this.actionType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.isProcessing = false,
  });

  SyncQueueItem copyWith({
    String? id,
    String? actionType,
    String? entityId,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    DateTime? nextRetryAt,
    bool? isProcessing,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
