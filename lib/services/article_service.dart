import 'dart:async';
import 'local_article_service.dart';
import 'remote/base_remote.dart';
import '../models/article.dart';
import '../utils/app_logger.dart';

class ArticleService {
  final LocalArticleService localDao;
  final BaseRemote remote;

  ArticleService({
    required this.localDao,
    required this.remote,
  });

  Stream<List<Article>> watchArticles() async* {
    // Step 1: Yield local cache immediately
    yield localDao.getAll();

    // Step 2: Try fetching from remote
    try {
      final remoteArticles = await remote.fetchArticles();
      
      // Step 3: Update localDao and yield updated list
      final now = DateTime.now();
      final updatedArticles = (remoteArticles as List<Article>).map((a) => a.copyWith(cachedAt: now)).toList();
      
      await localDao.saveAll(updatedArticles);
      yield localDao.getAll();
    } catch (e) {
      AppLogger.w("[CACHE] Remote fetch failed, serving cache");
      // Flow continues - local cache already yielded in Step 1
    }
  }

  Future<void> fetchNextPage(int offset, int limit) async {
    try {
      final remoteArticles = await remote.fetchArticles(limit: limit, offset: offset);
      final now = DateTime.now();
      final updatedArticles = (remoteArticles as List<Article>).map((a) => a.copyWith(cachedAt: now)).toList();
      await localDao.saveAll(updatedArticles);
    } catch (e) {
      AppLogger.w("[CACHE] Remote page fetch failed: $e");
    }
  }

  Future<Article?> getArticleById(String id) async {
    return localDao.getById(id);
  }

  Future<void> updateLocalArticle(Article article) async {
    await localDao.updateArticle(article);
  }

  bool shouldRefresh(List<Article> articles) {
    if (articles.isEmpty) return true;
    return localDao.isCacheExpired(articles.first);
  }
}
