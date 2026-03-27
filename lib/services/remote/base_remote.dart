import '../../models/article.dart';
import '../../models/sync_queue_item.dart';

abstract class BaseRemote {
  Future<List<Article>> fetchArticles({int limit = 10, int offset = 0});
  Future<void> applyAction(SyncQueueItem item);
}
