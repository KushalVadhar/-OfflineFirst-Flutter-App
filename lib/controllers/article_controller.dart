import 'package:flutter/foundation.dart';
import '../services/article_service.dart';
import '../models/article.dart';
import '../utils/app_logger.dart';

class ArticleController with ChangeNotifier {
  final ArticleService _repository;

  List<Article> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;

  ArticleController({required ArticleService repository}) : _repository = repository;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  Future<void> loadArticles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Initial load from local cache
      final localArticles = _repository.localDao.getAll();
      _articles = localArticles;
      notifyListeners();

      // Step 2: Refresh from remote in background
      await for (final freshArticles in _repository.watchArticles()) {
        _articles = freshArticles;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e("[ARTICLE_PROVIDER] Error loading articles: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isFetchingMore) return;
    _isFetchingMore = true;
    notifyListeners();

    try {
      // Offset is the current number of articles in the list
      await _repository.fetchNextPage(_articles.length, 10);
      
      // Local cache will have updated, so we need to refresh the list
      _articles = _repository.localDao.getAll();
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> updateLocalArticle(Article updatedArticle) async {
    // Optimistic UI update
    final index = _articles.indexWhere((a) => a.id == updatedArticle.id);
    if (index != -1) {
      _articles[index] = updatedArticle;
      notifyListeners();
    }

    await _repository.updateLocalArticle(updatedArticle);
  }
}
