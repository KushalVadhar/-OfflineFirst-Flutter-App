import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_first/services/sync/sync_queue_logic.dart';
import 'package:offline_first/services/local_queue_service.dart';
import 'package:offline_first/services/sync/sync_observability.dart';
import 'package:offline_first/services/sync/idempotency_helper.dart';
import 'package:offline_first/models/sync_queue_item.dart';

class MockLocalQueueService extends Mock implements LocalQueueService {}
class MockSyncObservability extends Mock implements SyncObservability {}

void main() {
  late SyncQueueLogic syncQueue;
  late MockLocalQueueService mockDao;
  late MockSyncObservability mockObs;

  setUpAll(() {
    registerFallbackValue(SyncQueueItem(
      id: '1',
      actionType: 'LIKE',
      entityId: 'e1',
      payload: '{}',
      createdAt: DateTime.now(),
      retryCount: 0,
    ));
  });

  setUp(() {
    mockDao = MockLocalQueueService();
    mockObs = MockSyncObservability();
    syncQueue = SyncQueueLogic(queueService: mockDao, observability: mockObs);
  });

  test('enqueue should replace existing action for same entity and type (LWW)', () async {
    final item2 = SyncQueueItem(
      id: 'id2',
      actionType: 'LIKE',
      entityId: 'article_1',
      payload: '{"isLiked": false}', 
      createdAt: DateTime.now(),
      retryCount: 0,
    );

    when(() => mockDao.getIdForAction('LIKE', 'article_1')).thenReturn('id1');
    when(() => mockDao.delete(any())).thenAnswer((_) async {});
    when(() => mockDao.save(any())).thenAnswer((_) async {});
    when(() => mockDao.pendingCount).thenReturn(1);

    await syncQueue.enqueue(item2);

    verify(() => mockDao.delete('id1')).called(1);
    verify(() => mockDao.save(item2)).called(1);
  });

  test('markFailed should schedule next attempt with exponential backoff', () async {
    final item = SyncQueueItem(
      id: 'id1',
      actionType: 'SAVE',
      entityId: 'e1',
      payload: '{}',
      createdAt: DateTime.now(),
      retryCount: 0, // First failure
    );

    when(() => mockDao.save(any())).thenAnswer((_) async {});

    await syncQueue.markFailed(item);

    expect(item.retryCount, 1);
    expect(item.nextRetryAt, isNotNull);
    final now = DateTime.now();
    // Base backoff is likely 5 or 10s. Let's check how long the Scheduled wait is.
    // In SyncQueueLogic: delaySeconds = baseBackoff * pow(2, retryCount - 1)
    // If base is 10s: 10 * 2^0 = 10s.
    final diff = item.nextRetryAt!.difference(now).inSeconds;
    expect(diff, closeTo(10, 2)); // Expecting around 10 seconds for first retry
  });

  test('IdempotencyHelper should generate unique keys for each action', () {
    final key1 = IdempotencyHelper.generateKey();
    final key2 = IdempotencyHelper.generateKey();
    
    expect(key1, isNot(key2));
    expect(key1.length, greaterThan(20)); // Basic UUID check
  });
}
