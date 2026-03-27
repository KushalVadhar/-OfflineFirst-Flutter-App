class AppConstants {
  static const Duration cacheTTL = Duration(minutes: 30);
  static const int maxRetries = 3;
  static const Duration baseBackoff = Duration(seconds: 5);
  static const String articlesBox = 'articles_box';
  static const String queueBox = 'queue_box';
}
