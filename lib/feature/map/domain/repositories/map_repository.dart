import 'package:lockguard/feature/map/data/models/map_location.dart';

abstract class MapRepository {
  Future<List<MapLocation>>
      fetchLockLocations(); // Changed to support multiple locks
  Future<List<MapLocation>>
      fetchReceiverLocations(); // NEW: Support multiple receivers
  Future<MapLocation> fetchLockLocation(); // Keep for backward compatibility
  Future<MapLocation?> fetchDeviceLocation();
  Future<bool> updateLockStatus(
      String lockId, String status); // Added lockId parameter
}
