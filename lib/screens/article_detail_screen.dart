import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../controllers/article_controller.dart';
import '../controllers/sync_controller.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({required this.article, super.key});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.article.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveInsight(Article article) async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final note = _noteController.text;
    final updated = article.copyWith(note: note);
    
    context.read<ArticleController>().updateLocalArticle(updated);
    context.read<SyncController>().enqueueAction(
      actionType: 'NOTE',
      entityId: article.id,
      payload: '{"note": "$note"}',
    );

    // Artificial delay for animation feel
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Insight archived offline", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncController, ArticleController>(
      builder: (context, syncProvider, articleProvider, child) {
        final article = articleProvider.articles.firstWhere(
          (a) => a.id == widget.article.id,
          orElse: () => widget.article,
        );

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'hero-${article.id}',
                      child: Container(
                        height: 450,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage("https://picsum.photos/seed/${article.id}/1200/1600"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.white,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              article.category.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -1,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=${article.id}"),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Editorial Team", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  Text("March 27, 2026 • 5 min read", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Color(0xFF1C1C1E),
                                fontSize: 19,
                                height: 1.7,
                                fontFamily: 'serif',
                              ),
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8, bottom: 4),
                                    child: Text(
                                      article.body.isNotEmpty ? article.body.substring(0, 1) : '',
                                      style: const TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w900,
                                        height: 0.8,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: article.body.isNotEmpty ? article.body.substring(1) : '',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          const Divider(thickness: 1, color: Colors.black12),
                          const SizedBox(height: 32),
                          const Text(
                            "Journal Your Thoughts",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Your insights are saved locally and synced when online.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9FB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                            ),
                            child: TextField(
                              controller: _noteController,
                              maxLines: 6,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                              decoration: InputDecoration(
                                hintText: "Start writing...",
                                hintStyle: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                                contentPadding: const EdgeInsets.all(20),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : () => _handleSaveInsight(article),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSaving ? Colors.grey[800] : Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      "Archived Insight", 
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 40,
                right: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _FloatingAction(
                            icon: article.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: article.isLiked ? Colors.red : Colors.white,
                            onPressed: () {
                              final updated = article.copyWith(isLiked: !article.isLiked);
                              context.read<ArticleController>().updateLocalArticle(updated);
                              context.read<SyncController>().enqueueAction(
                                actionType: 'LIKE',
                                entityId: article.id,
                                payload: '{"isLiked": ${updated.isLiked}}',
                              );
                              HapticFeedback.lightImpact();
                            },
                          ),
                          _FloatingAction(
                            icon: Icons.chat_bubble_outline,
                            color: Colors.white,
                            onPressed: () {},
                          ),
                          _FloatingAction(
                            icon: article.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: article.isSaved ? Colors.blue : Colors.white,
                            onPressed: () {
                              final updated = article.copyWith(isSaved: !article.isSaved);
                              context.read<ArticleController>().updateLocalArticle(updated);
                              context.read<SyncController>().enqueueAction(
                                actionType: 'SAVE',
                                entityId: article.id,
                                payload: '{"isSaved": ${updated.isSaved}}',
                              );
                              HapticFeedback.lightImpact();
                            },
                          ),
                          _FloatingAction(
                            icon: Icons.ios_share_rounded,
                            color: Colors.white,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _FloatingAction({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      onPressed: onPressed,
    );
  }
}
