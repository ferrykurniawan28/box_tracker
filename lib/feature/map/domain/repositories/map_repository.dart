import 'package:lockguard/feature/map/data/models/map_location.dart';

abstract class MapRepository {
  Future<MapLocation> fetchLockLocation();
  Future<MapLocation?> fetchDeviceLocation();
  Future<bool> updateLockStatus(String status);
}
