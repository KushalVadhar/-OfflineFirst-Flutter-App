import 'package:hive/hive.dart';
import '../utils/config/constants.dart';
import '../utils/app_logger.dart';
import '../models/article.dart';

class LocalArticleService {
  final Box<Article> box;

  LocalArticleService(this.box);

  List<Article> getAll() {
    return box.values.toList();
  }

  Article? getById(String id) {
    return box.get(id);
  }

  Future<void> saveAll(List<Article> articles) async {
    for (var article in articles) {
      await box.put(article.id, article);
    }
    AppLogger.i("[CACHE] Saved ${articles.length} articles to Hive");
  }

  Future<void> save(Article article) async {
    await box.put(article.id, article);
    AppLogger.i("[CACHE] Saved article: ${article.id}");
  }

  Future<void> updateArticle(Article article) async {
    await box.put(article.id, article);
    AppLogger.i("[CACHE] Updated article: ${article.id}");
  }

  bool isCacheExpired(Article article) {
    return DateTime.now().difference(article.cachedAt) > AppConstants.cacheTTL;
  }

  Future<void> clearAll() async {
    await box.clear();
  }
}
