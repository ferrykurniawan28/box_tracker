import 'package:location/location.dart';
import 'package:lockguard/feature/map/data/datasource/firebase_service.dart';
import '../../domain/repositories/map_repository.dart';
import '../models/map_location.dart';

class MapRepositoryImpl implements MapRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final Location _location = Location();

  @override
  Future<List<MapLocation>> fetchLockLocations() async {
    try {
      // Fetch all locks from Firebase
      final locks = await _firebaseService.fetchLocks();

      if (locks.isEmpty) {
        print('No locks found in Firebase');
      }

      return locks;
    } catch (e) {
      print('Error fetching lock locations: $e');
      // Return empty list on error instead of dummy data
      return [];
    }
  }

  @override
  Future<List<MapLocation>> fetchReceiverLocations() async {
    try {
      // Fetch all receivers from Firebase
      final receivers = await _firebaseService.fetchReceivers();

      if (receivers.isEmpty) {
        print('No receivers found in Firebase');
      }

      return receivers;
    } catch (e) {
      print('Error fetching receiver locations: $e');
      // Return empty list on error instead of dummy data
      return [];
    }
  }

  @override
  Future<MapLocation> fetchLockLocation() async {
    try {
      // Fetch all locks and return the first one for backward compatibility
      final locks = await _firebaseService.fetchLocks();

      if (locks.isEmpty) {
        throw Exception('No locks found in Firebase');
      }

      // Return the first lock
      return locks.first;
    } catch (e) {
      print('Error fetching lock location: $e');
      rethrow;
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
    try {
      // Call Firebase service to update lock status
      return await _firebaseService.updateLockStatus(lockId, status);
    } catch (e) {
      print('Error updating lock status: $e');
      return false;
    }
  }

  @override
  Future<List<MapLocation>> fetchLockHistory(String lockId,
      {int limit = 50}) async {
    try {
      return await _firebaseService.fetchLockHistory(lockId, limit: limit);
    } catch (e) {
      print('Error fetching lock history: $e');
      return [];
    }
  }

  @override
  Future<List<MapLocation>> fetchAllHistory({int limitPerLock = 20}) async {
    try {
      return await _firebaseService.fetchAllHistory(limitPerLock: limitPerLock);
    } catch (e) {
      print('Error fetching all history: $e');
      return [];
    }
  }
}
