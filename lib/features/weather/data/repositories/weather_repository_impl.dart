import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/api_keys.dart'; // Import API keys

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

class WeatherRepository {
  final Dio _dio = Dio();
  final Box _cache = Hive.box('weather_cache');

  // Use imported constants instead of hardcoded values
  static const String _baseUrl = ApiKeys.openWeatherBaseUrl;
  static const String _apiKey = ApiKeys.openWeatherMap;

  /// Get current weather for a city with caching
  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      // Check cache first
      final cacheKey = 'weather_$city';
      final cachedData = _cache.get(cacheKey);

      if (cachedData != null) {
        final cacheTime = cachedData['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Return cached data if less than 10 minutes old
        if (now - cacheTime < 600000) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      }

      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'q': city,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      // Cache the response
      await _cache.put(cacheKey, {
        'data': response.data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return response.data;
    } on DioException catch (e) {
      // Return cached data if available, even if expired
      final cachedData = _cache.get('weather_$city');
      if (cachedData != null) {
        return Map<String, dynamic>.from(cachedData['data']);
      }
      throw Exception('Failed to load weather: ${e.message}');
    }
  }

  /// Get 5-day forecast
  Future<Map<String, dynamic>> getFiveDayForecast(String city) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'q': city,
          'appid': _apiKey,
          'units': 'metric',
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to load forecast: ${e.message}');
    }
  }

  /// Get weather by coordinates
  Future<Map<String, dynamic>> getWeatherByCoords(
      double lat, double lon) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': _apiKey,
          'units': 'metric',
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to load weather by location: ${e.message}');
    }
  }
}
