import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/location_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Open ALL required boxes (this was missing 'bookmarks')
    await Hive.openBox('weather_cache');
    await Hive.openBox('news_cache');
    await Hive.openBox('bookmarks'); // <-- MISSING: Added this box
    await Hive.openBox('settings');

    print('All Hive boxes opened successfully');
  } catch (e) {
    print('Failed to initialize Hive: $e');
    // App will still run but without caching
  }

  // Initialize location service
  try {
    final locationService = LocationService();
    await locationService.initialize();
    print('Location service initialized successfully');
  } catch (e) {
    print('Failed to initialize location service: $e');
    // App will still run but without location features
  }

  runApp(const ProviderScope(child: NewsWeatherApp()));
}
