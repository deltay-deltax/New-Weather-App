import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:news_weather_app/core/constants/api_keys.dart';
import '../models/news_model.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository();
});

class NewsRepository {
  final Dio _dio = Dio();
  final Box _cache = Hive.box('news_cache');
  final Box _bookmarks = Hive.box('bookmarks');

  static const String _baseUrl = ApiKeys.newsApiBaseUrl;
  static const String _apiKey = ApiKeys.newsApi; // Replace with your actual key

  /// Safe type conversion helper for individual maps
  Map<String, dynamic> _safeMapConversion(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception(
          'Invalid data type: expected Map, got ${data.runtimeType}');
    }
  }

  /// Safe type conversion helper for lists of maps
  List<Map<String, dynamic>> _safeListConversion(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => _safeMapConversion(item)).toList();
    } else {
      throw Exception(
          'Invalid data type: expected List, got ${data.runtimeType}');
    }
  }

  /// Fetch top headlines with category filtering and return NewsModel objects
  Future<List<NewsModel>> getTopHeadlines({String category = ''}) async {
    try {
      final cacheKey = 'headlines_$category';
      final cachedData = _cache.get(cacheKey);

      // Check cache first (5 minutes expiry - reduced for better freshness)
      if (cachedData != null && cachedData is Map) {
        final cacheTime = cachedData['timestamp'] as int? ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - cacheTime < 300000) {
          // 5 minutes
          print('📱 Loading from cache: $cacheKey');
          final articlesData = _safeListConversion(cachedData['data']);
          final cachedArticles = articlesData
              .map((json) => NewsModel.fromJson(json))
              .where((article) => article.title != null && article.url != null)
              .toList();

          // Only return cache if it has articles, otherwise fetch fresh
          if (cachedArticles.isNotEmpty) {
            print(
                '✅ Cache hit: returning ${cachedArticles.length} cached articles');
            return cachedArticles;
          } else {
            print('⚠️ Cache empty, fetching fresh data...');
          }
        } else {
          print('⏰ Cache expired, fetching fresh data...');
        }
      }

      print('🌐 Fetching from API: category="$category"');

      // Build query parameters for US news (as per your requirement)
      final queryParams = <String, dynamic>{
        'country': 'us', // US news for better category coverage
        'apiKey': _apiKey,
        'pageSize': 100, // Increased from 50 to get more articles
      };

      // Add category if provided and supported
      if (category.isNotEmpty && _isSupportedCategory(category)) {
        queryParams['category'] = category;
        print('📂 Using category filter: $category');
      } else if (category.isNotEmpty) {
        print('❌ Unsupported category: $category, fetching all news');
      }

      print('🔗 API Request: $_baseUrl/top-headlines');
      print('📋 Query params: $queryParams');

      final response = await _dio.get(
        '$_baseUrl/top-headlines',
        queryParameters: queryParams,
      );

      // Safe type conversion for API response
      final responseData = _safeMapConversion(response.data);
      final articlesRaw = responseData['articles'] as List? ?? [];

      print('📊 API Response Status: ${responseData['status']}');
      print(
          '📈 Total results from API: ${responseData['totalResults'] ?? 'Unknown'}');
      print('📦 Raw articles received: ${articlesRaw.length}');

      // Less strict filtering - only remove articles with critical missing data
      final articlesJson = articlesRaw
          .where((article) => article != null)
          .map((article) => _safeMapConversion(article))
          .where((article) {
        final hasTitle = article['title'] != null &&
            article['title'] != '[Removed]' &&
            article['title'].toString().trim().isNotEmpty;
        final hasUrl = article['url'] != null &&
            article['url'].toString().trim().isNotEmpty;

        if (!hasTitle || !hasUrl) {
          print(
              '🚫 Filtered out article: title="${article['title']}", url="${article['url']}"');
        }

        return hasTitle && hasUrl;
      }).toList();

      print('✂️ After filtering: ${articlesJson.length} articles remain');

      // Convert to NewsModel objects with detailed error reporting
      final articles = <NewsModel>[];
      for (int i = 0; i < articlesJson.length; i++) {
        try {
          final article = NewsModel.fromJson(articlesJson[i]);
          articles.add(article);
        } catch (e) {
          print('❌ Error converting article $i to NewsModel: $e');
          print('🔍 Problematic article data: ${articlesJson[i]}');
        }
      }

      print(
          '🎯 Successfully converted ${articles.length} articles to NewsModel');

      // Cache the JSON data (not NewsModel objects) with current timestamp
      await _cache.put(cacheKey, {
        'data': articlesJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('💾 Cached ${articlesJson.length} articles for key: $cacheKey');

      return articles;
    } on DioException catch (e) {
      print('🚨 DioException: ${e.response?.statusCode} - ${e.message}');
      print('📄 Response data: ${e.response?.data}');

      // Handle specific error codes
      if (e.response?.statusCode == 401) {
        print('🔑 API authentication failed for category: $category');
        throw Exception(
            'Invalid API key. Please check your NewsAPI key configuration.');
      } else if (e.response?.statusCode == 429) {
        print('⏳ Rate limit exceeded');
        throw Exception('Too many requests. Please try again later.');
      } else if (e.response?.statusCode == 426) {
        print('⬆️ Upgrade required');
        throw Exception('Please upgrade your NewsAPI plan for this feature.');
      }

      // Try to return cached data as fallback
      final cachedData = _cache.get('headlines_$category');
      if (cachedData != null && cachedData is Map) {
        print('📂 Returning cached data due to API error');
        final articlesData = _safeListConversion(cachedData['data']);
        final fallbackArticles = articlesData
            .map((json) => NewsModel.fromJson(json))
            .where((article) => article.title != null && article.url != null)
            .toList();

        if (fallbackArticles.isNotEmpty) {
          print(
              '✅ Fallback: returning ${fallbackArticles.length} cached articles');
          return fallbackArticles;
        }
      }

      throw Exception('Failed to load news: ${e.message}');
    } catch (e) {
      print('💥 General error: $e');
      throw Exception('Failed to load news: $e');
    }
  }

  /// Check if category is supported by NewsAPI and our app
  bool _isSupportedCategory(String category) {
    const supportedCategories = ['business', 'technology', 'sports'];
    final isSupported = supportedCategories.contains(category.toLowerCase());
    print('🔍 Category "$category" supported: $isSupported');
    return isSupported;
  }

  /// Search news articles with enhanced error handling
  Future<List<NewsModel>> searchNews(String query) async {
    if (query.trim().isEmpty) {
      print('🔍 Empty search query, returning empty list');
      return [];
    }

    try {
      print('🔎 Searching news for: "$query"');

      final response = await _dio.get(
        '$_baseUrl/everything',
        queryParameters: {
          'q': query.trim(),
          'sortBy': 'publishedAt',
          'apiKey': _apiKey,
          'pageSize': 50,
          'language': 'en',
        },
      );

      final responseData = _safeMapConversion(response.data);
      final articlesRaw = responseData['articles'] as List? ?? [];

      print('🔍 Search returned ${articlesRaw.length} articles for "$query"');

      final articlesJson = articlesRaw
          .where((article) => article != null)
          .map((article) => _safeMapConversion(article))
          .where((article) =>
              article['title'] != null &&
              article['title'] != '[Removed]' &&
              article['url'] != null &&
              article['title'].toString().trim().isNotEmpty)
          .toList();

      final articles = articlesJson
          .map((json) {
            try {
              return NewsModel.fromJson(json);
            } catch (e) {
              print('❌ Error converting search result to NewsModel: $e');
              return null;
            }
          })
          .where((article) => article != null)
          .cast<NewsModel>()
          .toList();

      print('✅ Search completed: ${articles.length} valid articles found');
      return articles;
    } on DioException catch (e) {
      print('🚨 Search DioException: ${e.response?.statusCode} - ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception(
            'API authentication failed. Please check your API key.');
      }
      throw Exception('Failed to search news: ${e.message}');
    }
  }

  /// Bookmark management with enhanced logging
  Future<void> bookmarkArticle(NewsModel article) async {
    if (article.url == null || article.url!.isEmpty) {
      throw Exception('Cannot bookmark article without URL');
    }

    try {
      final bookmarkData = {
        ...article.toJson(),
        'bookmarkedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _bookmarks.put(article.url!, bookmarkData);
      print('🔖 Bookmarked article: "${article.title}"');
    } catch (e) {
      print('❌ Error bookmarking article: $e');
      throw Exception('Failed to bookmark article');
    }
  }

  Future<void> removeBookmark(String url) async {
    try {
      await _bookmarks.delete(url);
      print('🗑️ Removed bookmark: $url');
    } catch (e) {
      print('❌ Error removing bookmark: $e');
      throw Exception('Failed to remove bookmark');
    }
  }

  bool isBookmarked(String url) {
    final bookmarked = _bookmarks.containsKey(url);
    return bookmarked;
  }

  List<NewsModel> getBookmarks() {
    try {
      final bookmarks = _bookmarks.values
          .map((bookmark) {
            try {
              final safeMap = _safeMapConversion(bookmark);
              return NewsModel.fromJson(safeMap);
            } catch (e) {
              print('❌ Error converting bookmark to NewsModel: $e');
              return null;
            }
          })
          .where((article) => article != null)
          .cast<NewsModel>()
          .toList();

      // Sort by bookmark date (newest first)
      bookmarks.sort((a, b) {
        try {
          final aData = _bookmarks.get(a.url!) as Map?;
          final bData = _bookmarks.get(b.url!) as Map?;
          final aTime = aData?['bookmarkedAt'] as int? ?? 0;
          final bTime = bData?['bookmarkedAt'] as int? ?? 0;
          return bTime.compareTo(aTime);
        } catch (e) {
          return 0;
        }
      });

      print('📚 Retrieved ${bookmarks.length} bookmarks');
      return bookmarks;
    } catch (e) {
      print('❌ Error getting bookmarks: $e');
      return [];
    }
  }

  /// Cache management methods
  Future<void> clearCacheForCategory(String category) async {
    try {
      final cacheKey = 'headlines_$category';
      await _cache.delete(cacheKey);
      print('🗑️ Cleared cache for category: $category');
    } catch (e) {
      print('❌ Error clearing cache for category $category: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      await _cache.clear();
      print('🗑️ Cleared all news cache');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  Future<void> clearOldCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      for (final key in _cache.keys) {
        final data = _cache.get(key);
        if (data is Map && data['timestamp'] != null) {
          final timestamp = data['timestamp'] as int;
          if (now - timestamp > 86400000) {
            // 24 hours
            keysToDelete.add(key.toString());
          }
        }
      }

      for (final key in keysToDelete) {
        await _cache.delete(key);
      }

      print('🧹 Cleared ${keysToDelete.length} old cache entries');
    } catch (e) {
      print('❌ Error clearing old cache: $e');
    }
  }

  /// Debug and utility methods
  Map<String, dynamic> getCacheInfo() {
    final info = {
      'cacheSize': _cache.length,
      'bookmarksCount': _bookmarks.length,
      'cacheKeys': _cache.keys.toList(),
    };
    print('ℹ️ Cache info: $info');
    return info;
  }

  /// Test API connection
  Future<bool> testApiConnection() async {
    try {
      print('🔌 Testing API connection...');
      final response = await _dio.get(
        '$_baseUrl/top-headlines',
        queryParameters: {
          'country': 'us',
          'pageSize': 1,
          'apiKey': _apiKey,
        },
      );

      final success = response.statusCode == 200;
      print('🔌 API connection test: ${success ? "SUCCESS" : "FAILED"}');
      return success;
    } catch (e) {
      print('🔌 API connection test FAILED: $e');
      return false;
    }
  }

  /// Get supported categories
  List<String> getSupportedCategories() {
    return ['business', 'technology', 'sports'];
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{};

    for (final key in _cache.keys) {
      final data = _cache.get(key);
      if (data is Map && data['data'] is List) {
        final articles = data['data'] as List;
        final timestamp = data['timestamp'] as int? ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;

        stats[key.toString()] = {
          'articleCount': articles.length,
          'ageMinutes': (age / 60000).round(),
          'isValid': age < 300000, // 5 minutes
        };
      }
    }

    return stats;
  }
}
