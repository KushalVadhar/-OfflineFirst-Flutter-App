import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_card.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bookmarks", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<ArticleController>(
        builder: (context, controller, child) {
          final savedArticles = controller.articles.where((a) => a.isSaved).toList();

          if (savedArticles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No saved articles yet",
                    style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedArticles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ArticleCard(article: savedArticles[index]),
              );
            },
          );
        },
      ),
    );
  }
}
