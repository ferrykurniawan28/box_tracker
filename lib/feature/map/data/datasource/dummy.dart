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
    // Create a single lock for backward compatibility
    final lockInfo = LockInfo(location: _defaultLockLocation);

    // Create default receivers
    final defaultReceivers = [
      MapLocation(
        latitude: -6.218987,
        longitude: 106.801851,
        lockStatus: "receiver",
        timestamp: DateTime.now(),
        deviceId: "RECEIVER_001",
      ),
      MapLocation(
        latitude: -6.257766,
        longitude: 106.891851,
        lockStatus: "receiver",
        timestamp: DateTime.now(),
        deviceId: "RECEIVER_002",
      ),
    ];

    return MapData(
      locks: [lockInfo],
      receivers: defaultReceivers, // NEW: Include receivers
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

  // Helper method to get random success or failed image path
  static String getRandomUnlockImage(bool isAuthorized) {
    final random = Random();
    if (isAuthorized) {
      // Success images (1-4)
      final imageNumber = random.nextInt(4) + 1;
      return 'assets/images/sucess-$imageNumber.jpeg';
    } else {
      // Failed/intruder images (1-4)
      final imageNumber = random.nextInt(4) + 1;
      return 'assets/images/failed-$imageNumber.jpeg';
    }
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
