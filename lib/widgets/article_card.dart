import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../controllers/article_controller.dart';
import '../controllers/sync_controller.dart';
import '../screens/article_detail_screen.dart';

class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({required this.article, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncController>(
      builder: (context, syncProvider, child) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'hero-${article.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      "https://picsum.photos/seed/${article.id}/800",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=${article.id}"),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              "Editorial Team", 
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (article.note != null && article.note!.isNotEmpty)
                            const Icon(Icons.edit_note, size: 18, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, height: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text("5 Mins Read", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _SmallIconButton(
                            icon: article.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: article.isSaved ? Colors.blue : Colors.grey,
                            onPressed: () {
                              final updated = article.copyWith(isSaved: !article.isSaved);
                              context.read<ArticleController>().updateLocalArticle(updated);
                              context.read<SyncController>().enqueueAction(
                                actionType: 'SAVE',
                                entityId: article.id,
                                payload: '{"isSaved": ${updated.isSaved}}',
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _SmallIconButton(
                            icon: article.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: article.isLiked ? Colors.red : Colors.grey,
                            onPressed: () {
                              final updated = article.copyWith(isLiked: !article.isLiked);
                              context.read<ArticleController>().updateLocalArticle(updated);
                              context.read<SyncController>().enqueueAction(
                                actionType: 'LIKE',
                                entityId: article.id,
                                payload: '{"isLiked": ${updated.isLiked}}',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SmallIconButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
