import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../data/models/news_model.dart';

class NewsDetailScreen extends ConsumerWidget {
  final NewsModel article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = article.urlToImage;
    final title = article.title ?? 'No Title';
    final description = article.description ?? '';
    final content = article.content ?? '';
    final source = article.source?.name ?? 'Unknown Source';
    final author = article.author ?? 'Unknown Author';
    final publishedAt = article.publishedAt;
    final url = article.url;

    // Parse publication date
    DateTime? publishDate;
    String formattedDate = 'Unknown Date';
    if (publishedAt != null) {
      try {
        publishDate = DateTime.parse(publishedAt);
        formattedDate = DateFormat('MMM dd, yyyy • HH:mm').format(publishDate);
      } catch (e) {
        formattedDate = 'Invalid Date';
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null && imageUrl.isNotEmpty
                  ? Hero(
                      tag: 'news-image-${article.url}',
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade300,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 64),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.article, size: 64),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareArticle(context),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                onPressed: () => _openInBrowser(context),
              ),
            ],
          ),

          // Article Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and Date
                  Row(
                    children: [
                      Chip(
                        label: Text(source),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  // Author
                  if (author.isNotEmpty && author != 'Unknown Author')
                    Text(
                      'By $author',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                    ),

                  const SizedBox(height: 16),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                    ),

                  const SizedBox(height: 16),

                  // Content
                  if (content.isNotEmpty)
                    Text(
                      content.replaceAll('[+', '').replaceAll('chars]', ''),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),

                  const SizedBox(height: 24),

                  // Read Full Article Button
                  if (url != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openInBrowser(context),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Read Full Article'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                  const SizedBox(height: 50), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareArticle(BuildContext context) {
    final title = article.title ?? 'News Article';
    final url = article.url ?? '';
    Share.share('$title\n\n$url', subject: title);
  }

  Future<void> _openInBrowser(BuildContext context) async {
    final url = article.url;
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar(context, 'Cannot open article URL');
        }
      } catch (e) {
        _showSnackBar(context, 'Invalid article URL');
      }
    } else {
      _showSnackBar(context, 'No article URL available');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
