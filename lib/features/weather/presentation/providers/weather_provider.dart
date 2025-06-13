import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../../../core/services/location_service.dart'; // <-- FIXED: 4 dots instead of 3

// Theme provider for app-wide theme management
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  /// Toggle between light and dark themes
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Set specific theme mode
  void setTheme(ThemeMode mode) {
    state = mode;
  }

  /// Reset to system theme
  void setSystemTheme() {
    state = ThemeMode.system;
  }
}

// Weather-related providers
final selectedCityProvider = StateProvider<String>((ref) => 'London');

final currentWeatherProvider = AsyncNotifierProvider.autoDispose<
    CurrentWeatherNotifier, Map<String, dynamic>>(CurrentWeatherNotifier.new);

final forecastProvider =
    AsyncNotifierProvider.autoDispose<ForecastNotifier, Map<String, dynamic>>(
        ForecastNotifier.new);

final locationWeatherProvider = AsyncNotifierProvider.autoDispose<
    LocationWeatherNotifier, Map<String, dynamic>>(LocationWeatherNotifier.new);

/// Manages current weather data for selected city
class CurrentWeatherNotifier
    extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final city = ref.watch(selectedCityProvider);
    final repository = ref.read(weatherRepositoryProvider);
    return await repository.getCurrentWeather(city);
  }

  /// Refresh current weather data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Manages 5-day forecast data for selected city
class ForecastNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final city = ref.watch(selectedCityProvider);
    final repository = ref.read(weatherRepositoryProvider);
    return await repository.getFiveDayForecast(city);
  }

  /// Refresh forecast data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Manages weather data for user's current location
class LocationWeatherNotifier
    extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    try {
      // FIXED: Proper instantiation of LocationService
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      // Get weather repository and fetch weather by coordinates
      final repository = ref.read(weatherRepositoryProvider);
      final weatherData = await repository.getWeatherByCoords(
        position.latitude,
        position.longitude,
      );

      // Add location info to the weather data
      return {
        ...weatherData,
        'isCurrentLocation': true,
        'coordinates': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      };
    } on LocationException catch (e) {
      // FIXED: Proper handling of LocationException
      throw Exception('Location Error: ${e.message}');
    } catch (e) {
      // Handle other errors
      throw Exception('Failed to get location weather: ${e.toString()}');
    }
  }

  /// Refresh location weather data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Get weather using last known position as fallback
  Future<Map<String, dynamic>?> getWeatherFromLastKnownPosition() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getLastKnownPosition();

      if (position != null) {
        final repository = ref.read(weatherRepositoryProvider);
        return await repository.getWeatherByCoords(
          position.latitude,
          position.longitude,
        );
      }
      return null;
    } catch (e) {
      print('Failed to get weather from last known position: $e');
      return null;
    }
  }
}

/// Multi-city weather comparison provider
final multiCityWeatherProvider = StateNotifierProvider.autoDispose<
    MultiCityWeatherNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return MultiCityWeatherNotifier(ref.read(weatherRepositoryProvider));
});

/// Manages weather data for multiple cities for comparison
class MultiCityWeatherNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final WeatherRepository _repository;
  final List<String> _cities = ['London', 'New York', 'Tokyo', 'Sydney'];

  MultiCityWeatherNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _fetchAllCities();
  }

  /// Fetch weather data for all cities
  Future<void> _fetchAllCities() async {
    state = const AsyncValue.loading();

    try {
      final results = await Future.wait(
        _cities.map((city) => _repository.getCurrentWeather(city)),
      );
      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Add a new city to comparison list
  void addCity(String city) {
    if (!_cities.contains(city) && city.isNotEmpty) {
      _cities.add(city);
      _fetchAllCities();
    }
  }

  /// Remove a city from comparison list
  void removeCity(String city) {
    if (_cities.contains(city) && _cities.length > 1) {
      _cities.remove(city);
      _fetchAllCities();
    }
  }

  /// Refresh all cities weather data
  void refresh() {
    _fetchAllCities();
  }

  /// Get current cities list
  List<String> get cities => List.unmodifiable(_cities);
}

/// Provider for location permission status
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final locationService = LocationService();
  return await locationService.hasLocationPermission();
});

/// Provider for checking if location services are available
final locationServiceAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final locationService = LocationService();
    await locationService.getCurrentLocation();
    return true;
  } catch (e) {
    return false;
  }
});
