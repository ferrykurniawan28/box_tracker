import 'dart:math';

import '../models/map_location.dart';
import '../models/map_data.dart';

class MapDummyData {
  static final MapLocation _defaultLockLocation = MapLocation(
    latitude: -6.2088,
    longitude: 106.8456,
    lockStatus: "locked",
    timestamp: DateTime(2024, 1, 1),
    deviceId: "LOCK_GUARD_001", // Lock device identifier
  );

  // Removed _defaultDeviceLocation - now using real GPS for device location

  static MapData get initialMapData {
    return MapData(
      lockLocation: _defaultLockLocation,
      deviceLocation: null, // Device location now fetched from real GPS
      distanceInfo: "Calculating...",
      isTracking: false,
      countdown: 0,
    );
  }

  static MapLocation generateRandomLockLocation() {
    final random = Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.01; // ±0.005 degrees
    final lngOffset = (random.nextDouble() - 0.5) * 0.01; // ±0.005 degrees

    return MapLocation(
      latitude: _defaultLockLocation.latitude + latOffset,
      longitude: _defaultLockLocation.longitude + lngOffset,
      lockStatus: random.nextBool() ? "locked" : "unlocked",
      timestamp: DateTime.now(),
      deviceId: "LOCK_GUARD_001", // Keep consistent lock device ID
    );
  }

  // Removed generateRandomDeviceLocation - now using real GPS for device location

  static Future<Map<String, dynamic>> generateDummyFirebaseData() async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    final lockLocation = generateRandomLockLocation();

    return {
      'latitude': lockLocation.latitude,
      'longitude': lockLocation.longitude,
      'lock': lockLocation.lockStatus,
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': lockLocation.deviceId, // Include device ID in Firebase data
    };
  }

  static String calculateDistance(
      MapLocation lockLocation, MapLocation deviceLocation) {
    // Simple distance calculation (approximate)
    final latDiff = lockLocation.latitude - deviceLocation.latitude;
    final lngDiff = lockLocation.longitude - deviceLocation.longitude;
    final distance = (latDiff * latDiff + lngDiff * lngDiff).abs() *
        111; // Rough km conversion

    return "Distance: ${distance.toStringAsFixed(2)} km";
  }
}
