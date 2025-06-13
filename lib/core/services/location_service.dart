import 'package:geolocator/geolocator.dart';

/// Comprehensive location service for weather app
/// Handles location permissions, GPS access, and error scenarios
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Initialize location service with permission checks
  Future<void> initialize() async {
    await _checkLocationPermissions();
  }

  /// Get current user location with comprehensive error handling
  Future<Position> getCurrentLocation() async {
    // Step 1: Check if location services are enabled on device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
          'Location services are disabled. Please enable GPS in device settings.');
    }

    // Step 2: Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // Step 3: Request permission if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
            'Location permission denied. Please grant location access to get weather for your current location.');
      }
    }

    // Step 4: Handle permanently denied permissions
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
          'Location permissions are permanently denied. Please enable them in app settings to use location-based weather.');
    }

    try {
      // Step 5: Get current position with high accuracy settings
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // 15 second timeout
      );
    } catch (e) {
      // Handle various location errors
      if (e.toString().contains('timeout')) {
        throw LocationException(
            'Location request timed out. Please try again.');
      } else {
        throw LocationException(
            'Failed to get current location: ${e.toString()}');
      }
    }
  }

  /// Get last known position (faster but potentially outdated)
  /// Useful for quick location access without GPS activation
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );
    } catch (e) {
      print('Failed to get last known position: $e');
      return null;
    }
  }

  /// Check if location permission is currently granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open device settings for manual permission management
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Check location permissions privately during initialization
  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission not granted yet - will request when needed');
    }
  }

  /// Get real-time position stream for continuous location updates
  /// Useful for tracking location changes while app is active
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters movement
      ),
    );
  }

  /// Calculate distance between two geographic points in meters
  /// Useful for weather comparison between cities
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Get location accuracy description for user feedback
  String getAccuracyDescription(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Very low accuracy (~3000m)';
      case LocationAccuracy.low:
        return 'Low accuracy (~1000m)';
      case LocationAccuracy.medium:
        return 'Medium accuracy (~100m)';
      case LocationAccuracy.high:
        return 'High accuracy (~10m)';
      case LocationAccuracy.best:
        return 'Best accuracy (~3m)';
      case LocationAccuracy.bestForNavigation:
        return 'Navigation accuracy (~1m)';
      default:
        return 'Unknown accuracy';
    }
  }
}

/// Custom exception class for location-related errors
/// Provides user-friendly error messages for different scenarios
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

/// Location permission status enum for better error handling
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

/// Extension for easy permission status checking
extension LocationPermissionStatusExtension on LocationPermissionStatus {
  bool get isGranted => this == LocationPermissionStatus.granted;
  bool get isDenied => this == LocationPermissionStatus.denied;
  bool get isPermanentlyDenied =>
      this == LocationPermissionStatus.permanentlyDenied;
  bool get isServiceDisabled =>
      this == LocationPermissionStatus.serviceDisabled;

  String get userMessage {
    switch (this) {
      case LocationPermissionStatus.granted:
        return 'Location access granted';
      case LocationPermissionStatus.denied:
        return 'Location permission denied';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Location permission permanently denied. Please enable in settings.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location services are disabled. Please enable GPS.';
    }
  }
}
