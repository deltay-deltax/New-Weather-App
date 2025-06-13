import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_weather_app/features/news/data/models/news_model.dart';
import 'package:news_weather_app/features/news/data/repositories/news_repository_impl.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/news_list.dart';
import 'bookmarks_screen.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final categories = ref.read(categoriesProvider);
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final categories = ref.read(categoriesProvider);
        final selectedCategory = categories[_tabController.index];
        print('Tab changed to category: $selectedCategory'); // Debug log
        ref.read(newsCategoryProvider.notifier).state = selectedCategory;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final categoryLabels = ref.watch(categoryLabelsProvider);
    final bookmarkCount = ref.watch(bookmarksProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search news...',
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                },
              )
            : const Text('News'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          // Debug: Add cache clear button (remove in production)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _clearCacheAndRefresh(),
            tooltip: 'Clear cache and refresh',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.bookmark),
                onPressed: () => _navigateToBookmarks(),
              ),
              if (bookmarkCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$bookmarkCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: _isSearching
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: categoryLabels.map((label) => Tab(text: label)).toList(),
              ),
      ),
      body: _isSearching && searchQuery.isNotEmpty
          ? _buildSearchResults(searchResultsAsync)
          : _buildNewsContent(newsAsync),
    );
  }

  Widget _buildNewsContent(AsyncValue<List<NewsModel>> newsAsync) {
    return newsAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) {
        print('News error: $error'); // Debug log
        return _buildErrorState(error.toString());
      },
      data: (articles) {
        print('Received ${articles.length} articles'); // Debug log
        return _buildNewsList(articles);
      },
    );
  }

  Widget _buildSearchResults(AsyncValue<List<NewsModel>> searchResultsAsync) {
    return searchResultsAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      data: (articles) => articles.isEmpty
          ? _buildEmptySearchState()
          : _buildNewsList(articles),
    );
  }

  Widget _buildNewsList(List<NewsModel> articles) {
    if (articles.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        print('Pull to refresh triggered'); // Debug log
        if (_isSearching) {
          ref.refresh(searchResultsProvider.future);
        } else {
          ref.refresh(newsProvider.future);
        }
      },
      child: NewsList(articles: articles),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading news...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(newsProvider.future);
                  },
                  child: const Text('Retry'),
                ),
                ElevatedButton(
                  onPressed: () => _clearCacheAndRefresh(),
                  child: const Text('Clear Cache'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No news articles found.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _clearCacheAndRefresh(),
            child: const Text('Clear Cache & Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No search results found.'),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      }
    });
  }

  void _navigateToBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookmarksScreen()),
    );
  }

  // Debug function to clear cache and refresh
  void _clearCacheAndRefresh() async {
    try {
      final repository = ref.read(newsRepositoryProvider);
      final currentCategory = ref.read(newsCategoryProvider);

      // Clear cache for current category
      await repository.clearCacheForCategory(currentCategory);

      // Refresh the provider
      ref.refresh(newsProvider.future);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared and refreshed')),
      );
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
