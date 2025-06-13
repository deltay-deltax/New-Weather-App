import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_model.dart';
import 'news_card.dart';

/// Primary news list widget that accepts NewsModel objects directly
class NewsList extends ConsumerWidget {
  final List<NewsModel> articles;

  const NewsList({super.key, required this.articles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (articles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No articles found'),
            SizedBox(height: 8),
            Text(
              'Try refreshing or check your internet connection',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return NewsCard(article: article);
      },
    );
  }
}

/// Alternative version that accepts Maps and safely converts to NewsModel objects
class NewsListLegacy extends ConsumerWidget {
  final List<Map<String, dynamic>> articles;

  const NewsListLegacy({super.key, required this.articles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (articles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No articles found'),
            SizedBox(height: 8),
            Text(
              'Try refreshing or check your internet connection',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        try {
          final articleMap = Map<String, dynamic>.from(articles[index]);
          // Safely convert Map to NewsModel with error handling
          final newsModel = NewsModel.fromJson(articleMap);
          return NewsCard(article: newsModel);
        } catch (e) {
          // Handle conversion errors gracefully
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error loading article',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not parse article data',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
