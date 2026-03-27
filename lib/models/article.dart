import 'package:hive/hive.dart';

part 'article.g.dart';

@HiveType(typeId: 0)
class Article extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final bool isLiked;

  @HiveField(4)
  final bool isSaved;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final DateTime cachedAt;

  @HiveField(7)
  final String version;

  @HiveField(8)
  final String category;

  Article({
    required this.id,
    required this.title,
    required this.body,
    this.isLiked = false,
    this.isSaved = false,
    this.note,
    required this.cachedAt,
    required this.version,
    this.category = "General",
  });

  Article copyWith({
    String? id,
    String? title,
    String? body,
    bool? isLiked,
    bool? isSaved,
    String? note,
    DateTime? cachedAt,
    String? version,
    String? category,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      note: note ?? this.note,
      cachedAt: cachedAt ?? this.cachedAt,
      version: version ?? this.version,
      category: category ?? this.category,
    );
  }

  factory Article.fromFirestore(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      isLiked: map['isLiked'] as bool? ?? false,
      isSaved: map['isSaved'] as bool? ?? false,
      note: map['note'] as String?,
      cachedAt: DateTime.now(),
      version: map['version'] as String,
      category: map['category'] as String? ?? "General",
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'note': note,
      'version': version,
      'category': category,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
