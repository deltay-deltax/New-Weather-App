import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../data/models/news_model.dart';

// Main news provider for headlines - returns List<NewsModel>
final newsProvider =
    AsyncNotifierProvider.autoDispose<NewsNotifier, List<NewsModel>>(
  NewsNotifier.new,
);

// Category selection provider
final newsCategoryProvider = StateProvider<String>((ref) => '');

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider - returns List<NewsModel>
final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchNotifier, List<NewsModel>>(
  SearchNotifier.new,
);

// Bookmarks provider - manages List<NewsModel>
final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<NewsModel>>((ref) {
  return BookmarksNotifier(ref.read(newsRepositoryProvider));
});

// Categories list - REMOVED health and entertainment to avoid 401 errors
final categoriesProvider = Provider<List<String>>((ref) {
  return [
    '',
    'business',
    'technology',
    'sports'
  ]; // Only free-tier supported categories
});

final categoryLabelsProvider = Provider<List<String>>((ref) {
  return ['All', 'Business', 'Technology', 'Sports']; // Matching labels
});

/// Main news headlines notifier
class NewsNotifier extends AutoDisposeAsyncNotifier<List<NewsModel>> {
  @override
  Future<List<NewsModel>> build() async {
    ref.onDispose(() {
      print('NewsNotifier disposed');
    });

    // ✅ FIXED: Removed all provider modifications from build()
    final category = ref.watch(newsCategoryProvider);
    final repository = ref.read(newsRepositoryProvider);

    print('Building NewsNotifier for category: $category');

    // Periodically clear old cache
    repository.clearOldCache();

    final articles = await repository.getTopHeadlines(category: category);
    print('NewsNotifier loaded ${articles.length} articles');

    return articles;
    // ✅ FIXED: Let AsyncNotifier handle errors naturally - don't modify other providers
  }

  Future<void> refresh() async {
    print('Refreshing news...');
    // ✅ FIXED: Only invalidate self, don't modify other providers
    ref.invalidateSelf();
  }

  Future<void> changeCategory(String category) async {
    print('Changing category to: $category');
    ref.read(newsCategoryProvider.notifier).state = category;
  }
}

/// Search results notifier with debouncing
class SearchNotifier extends AutoDisposeAsyncNotifier<List<NewsModel>> {
  Timer? _debounceTimer;

  @override
  Future<List<NewsModel>> build() async {
    // Use ref.onDispose to clean up timer
    ref.onDispose(() {
      print('SearchNotifier disposed');
      _debounceTimer?.cancel();
    });

    final query = ref.watch(searchQueryProvider);

    if (query.trim().isEmpty) {
      return [];
    }

    print('SearchNotifier building for query: "$query"');

    // Create a completer for the debounced result
    final completer = Completer<List<NewsModel>>();

    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Set up new debounced timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        print('Executing search for: "$query"');
        final repository = ref.read(newsRepositoryProvider);
        final results = await repository.searchNews(query);

        if (!completer.isCompleted) {
          print('Search completed with ${results.length} results');
          completer.complete(results);
        }
      } catch (e) {
        print('Search error: $e');
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

  Future<void> search(String query) async {
    print('Initiating search for: "$query"');
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void clearSearch() {
    print('Clearing search');
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
  }
}

/// Bookmarks state notifier - manages NewsModel objects
class BookmarksNotifier extends StateNotifier<List<NewsModel>> {
  final NewsRepository _repository;

  BookmarksNotifier(this._repository) : super([]) {
    print('BookmarksNotifier initialized');
    _loadBookmarks();
  }

  void _loadBookmarks() {
    try {
      final bookmarks = _repository.getBookmarks();
      print('Loaded ${bookmarks.length} bookmarks');
      state = bookmarks;
    } catch (e) {
      print('Error loading bookmarks: $e');
      state = [];
    }
  }

  Future<void> toggleBookmark(NewsModel article) async {
    if (article.url == null || article.url!.isEmpty) {
      print('Cannot bookmark article without URL');
      return;
    }

    try {
      final isCurrentlyBookmarked = _repository.isBookmarked(article.url!);

      if (isCurrentlyBookmarked) {
        await _repository.removeBookmark(article.url!);
        print('Removed bookmark for: ${article.title}');
      } else {
        await _repository.bookmarkArticle(article);
        print('Added bookmark for: ${article.title}');
      }

      // Reload bookmarks to update UI
      _loadBookmarks();
    } catch (e) {
      print('Error toggling bookmark: $e');
    }
  }

  bool isBookmarked(String url) {
    return _repository.isBookmarked(url);
  }

  Future<void> removeBookmark(String url) async {
    try {
      await _repository.removeBookmark(url);
      print('Removed bookmark: $url');
      _loadBookmarks();
    } catch (e) {
      print('Error removing bookmark: $e');
    }
  }

  Future<void> clearAllBookmarks() async {
    try {
      final currentBookmarks = List<NewsModel>.from(state);
      for (final bookmark in currentBookmarks) {
        if (bookmark.url != null) {
          await _repository.removeBookmark(bookmark.url!);
        }
      }
      print('Cleared all bookmarks');
      _loadBookmarks();
    } catch (e) {
      print('Error clearing all bookmarks: $e');
    }
  }

  int get bookmarkCount => state.length;

  List<NewsModel> get bookmarks => List.unmodifiable(state);
}

/// Connectivity provider for offline/online status
final connectivityProvider = StateProvider<bool>((ref) => true);

/// Cache info provider for debugging
final cacheInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.read(newsRepositoryProvider);
  return repository.getCacheInfo();
});

/// Combined loading state provider
final combinedLoadingProvider = Provider<bool>((ref) {
  final newsAsync = ref.watch(newsProvider);
  final searchAsync = ref.watch(searchResultsProvider);

  return newsAsync.isLoading || searchAsync.isLoading;
});

/// News statistics provider
final newsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final newsAsync = ref.watch(newsProvider);
  final bookmarks = ref.watch(bookmarksProvider);
  final cacheInfo = ref.watch(cacheInfoProvider);

  return {
    'totalArticles': newsAsync.valueOrNull?.length ?? 0,
    'bookmarksCount': bookmarks.length,
    'cacheSize': cacheInfo['cacheSize'] ?? 0,
    'hasError': newsAsync.hasError,
    'isLoading': newsAsync.isLoading,
  };
});
