import 'dart:async';
import 'dart:convert';
import '../../utils/app_logger.dart';
import '../../models/article.dart';
import '../../models/sync_queue_item.dart';
import 'base_remote.dart';

class MockRemote implements BaseRemote {
  static final List<Article> _mockServerDb = List.generate(63, (i) {
    final categories = ['Design', 'Technology', 'Business', 'Politics', 'Entertainment', 'Sports', 'Science'];
    final titles = [
      'The Shift in Design Thinking',
      'The Future of Sustainable Tech',
      'Economic Resilience in 2026',
      'Global Policy Transformations',
      'The Golden Era of Digital Art',
      'Innovation in Sports Science',
      'Quantum Computing Breakthroughs'
    ];

    final category = categories[i % categories.length];
    final title = '${titles[i % titles.length]} • Part ${i ~/ 7 + 1}';
    
    return Article(
      id: '${i + 1}',
      title: title,
      body: 'Article #${i + 1} - $category: This comprehensive guide covers the latest advancements in $category and its global impact in 2026. ' * 8,
      cachedAt: DateTime.now(),
      version: '1',
      category: category,
    );
  });

  @override
  Future<List<Article>> fetchArticles({int limit = 10, int offset = 0}) async {
    AppLogger.i("[MOCK_REMOTE] Fetching articles (limit: $limit, offset: $offset)...");
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulated network latency
    
    if (offset >= _mockServerDb.length) return [];
    
    final end = (offset + limit) < _mockServerDb.length ? (offset + limit) : _mockServerDb.length;
    return List.from(_mockServerDb.getRange(offset, end));
  }

  @override
  Future<void> applyAction(SyncQueueItem item) async {
    AppLogger.i("[MOCK_REMOTE] Applying action ${item.actionType} to server...");
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simulate a failure 30% of the time to test retries
    // final random = DateTime.now().millisecond % 10;
    // if (random < 3) throw Exception("Transient server error");

    final action = item.actionType.toUpperCase();
    final payloadMap = jsonDecode(item.payload);
    
    final index = _mockServerDb.indexWhere((a) => a.id == item.entityId);
    if (index != -1) {
      if (action == 'LIKE') {
        _mockServerDb[index] = _mockServerDb[index].copyWith(isLiked: payloadMap['isLiked']);
      } else if (action == 'SAVE') {
        _mockServerDb[index] = _mockServerDb[index].copyWith(isSaved: payloadMap['isSaved']);
      } else if (action == 'NOTE') {
        _mockServerDb[index] = _mockServerDb[index].copyWith(note: payloadMap['note']);
      }
      AppLogger.i("[MOCK_REMOTE] Action applied successfully: ${item.id}");
    }
  }
}
