import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_card.dart';
import '../widgets/skeleton_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ArticleController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Explore", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ArticleController>().loadArticles(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: "Search news, topics...",
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<ArticleController>(
                builder: (context, controller, child) {
                  if (controller.isLoading && controller.articles.isEmpty) {
                    return ListView.builder(
                      itemCount: 6,
                      itemBuilder: (context, index) => const SkeletonCard(),
                    );
                  }

                  final filtered = controller.articles.where((a) =>
                    a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    a.body.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();

                  if (filtered.isEmpty && !controller.isLoading) {
                     return const Center(child: Text("No articles found. Drag down to refresh."));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length + (controller.isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ArticleCard(article: filtered[index]),
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
