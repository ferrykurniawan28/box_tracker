import 'package:dio/dio.dart';
import 'package:location/location.dart';
import 'package:lockguard/feature/map/data/datasource/dummy.dart';
import '../../domain/repositories/map_repository.dart';
import '../models/map_location.dart';

class MapRepositoryImpl implements MapRepository {
  final String _firebaseUrl =
      "https://gps-lock-application-default-rtdb.asia-southeast1.firebasedatabase.app/gps.json";
  final Location _location = Location();
  // TODO: Enable real Firebase data by setting this to false
  // TODO: Test Firebase connectivity and data format
  final bool _useDummyData =
      true; // Switch between real and dummy data for LOCK only
  // Device location now always uses real GPS
  final Dio _dio = Dio();

  @override
  Future<List<MapLocation>> fetchLockLocations() async {
    if (_useDummyData) {
      // Generate multiple dummy locks for testing
      final List<MapLocation> locks = [];

      // Generate 3 dummy locks with different locations around Jakarta
      final lockPositions = [
        {"lat": -6.2088, "lng": 106.8456, "id": "LOCK_001", "status": "locked"},
        {
          "lat": -6.1751,
          "lng": 106.8650,
          "id": "LOCK_002",
          "status": "unlocked"
        },
        {"lat": -6.2615, "lng": 106.7800, "id": "LOCK_003", "status": "locked"},
      ];

      for (int i = 0; i < lockPositions.length; i++) {
        final pos = lockPositions[i];
        locks.add(MapLocation(
          latitude: pos["lat"] as double,
          longitude: pos["lng"] as double,
          lockStatus: pos["status"] as String,
          timestamp: DateTime.now().subtract(Duration(minutes: i * 5)),
          deviceId: pos["id"] as String,
        ));
      }

      return locks;
    } else {
      // Real implementation would fetch multiple locks from Firebase
      try {
        // For now, return single lock in a list for compatibility
        final singleLock = await fetchLockLocation();
        return [singleLock];
      } catch (e) {
        // Return empty list on error
        return [];
      }
    }
  }

  @override
  Future<List<MapLocation>> fetchReceiverLocations() async {
    if (_useDummyData) {
      // Generate multiple dummy receivers for testing
      final List<MapLocation> receivers = [];

      // Generate 2 dummy receivers with different locations around Jakarta
      final receiverPositions = [
        {"lat": -6.218987, "lng": 106.801851, "id": "RECEIVER_001"},
        {"lat": -6.200000, "lng": 106.816666, "id": "RECEIVER_002"},
      ];

      for (int i = 0; i < receiverPositions.length; i++) {
        final pos = receiverPositions[i];
        receivers.add(MapLocation(
          latitude: pos["lat"] as double,
          longitude: pos["lng"] as double,
          lockStatus: "receiver", // Identify as receiver
          timestamp: DateTime.now().subtract(Duration(minutes: i * 2)),
          deviceId: pos["id"] as String,
        ));
      }

      return receivers;
    } else {
      // Real implementation would fetch multiple receivers from Firebase
      try {
        // For now, return single hardcoded receiver for compatibility
        final receiver = MapLocation(
          latitude: -6.218987,
          longitude: 106.801851,
          lockStatus: "receiver",
          timestamp: DateTime.now(),
          deviceId: "RECEIVER_001",
        );
        return [receiver];
      } catch (e) {
        // Return empty list on error
        return [];
      }
    }
  }

  @override
  Future<MapLocation> fetchLockLocation() async {
    if (_useDummyData) {
      // Use dummy data
      final dummyData = await MapDummyData.generateDummyFirebaseData();
      return MapLocation.fromJson(dummyData);
    } else {
      // Use real Firebase data
      try {
        final response = await _dio.get(_firebaseUrl);
        if (response.statusCode == 200) {
          final data = response.data;
          return MapLocation.fromJson(data);
        } else {
          throw Exception('Failed to fetch location: ${response.statusCode}');
        }
      } catch (e) {
        // Fallback to dummy data on error
        final dummyData = await MapDummyData.generateDummyFirebaseData();
        return MapLocation.fromJson(dummyData);
      }
    }
  }

  @override
  Future<MapLocation?> fetchDeviceLocation() async {
    // Always use real GPS location for current device
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print("Location service not enabled");
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print("Location permission not granted");
          return null;
        }
      }

      print("Getting current device location...");
      final locationData = await _location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        print("Unable to get location coordinates");
        return null;
      }

      return MapLocation(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        lockStatus: "device",
        timestamp: DateTime.now(),
        deviceId:
            "CURRENT_DEVICE", // TODO: Get actual device ID from device_info_plus package
      );
    } catch (e) {
      print("Error getting device location: $e");
      // Return null instead of fallback to dummy data - device location should be real
      return null;
    }
  }

  @override
  Future<bool> updateLockStatus(String lockId, String status) async {
    // Simulate API call to update lock status for specific lock
    await Future.delayed(const Duration(milliseconds: 300));

    if (_useDummyData) {
      // For dummy data, just return success
      print("Updating lock $lockId to status: $status");
      return true;
    } else {
      // Real implementation would call Firebase API with lockId
      try {
        // Implement actual Firebase update here
        // Would update specific lock by lockId
        return true;
      } catch (e) {
        return false;
      }
    }
  }
}
