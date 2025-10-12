import 'package:lockguard/feature/map/data/models/map_location.dart';
import 'package:latlong2/latlong.dart';

class LockInfo {
  final MapLocation location;
  final List<LatLng> deviceToLockRoute; // Route from device to this lock
  final List<LatLng> receiverToLockRoute; // Route from receiver to this lock

  const LockInfo({
    required this.location,
    this.deviceToLockRoute = const [],
    this.receiverToLockRoute = const [],
  });

  LockInfo copyWith({
    MapLocation? location,
    List<LatLng>? deviceToLockRoute,
    List<LatLng>? receiverToLockRoute,
  }) {
    return LockInfo(
      location: location ?? this.location,
      deviceToLockRoute: deviceToLockRoute ?? this.deviceToLockRoute,
      receiverToLockRoute: receiverToLockRoute ?? this.receiverToLockRoute,
    );
  }

  @override
  String toString() {
    return 'LockInfo(location: $location, deviceRoute: ${deviceToLockRoute.length} points, receiverRoute: ${receiverToLockRoute.length} points)';
  }
}

class MapData {
  final List<LockInfo> locks;
  final MapLocation? deviceLocation;
  final String distanceInfo;
  final bool isTracking;
  final int countdown;
  final bool isLoadingRoutes;

  const MapData({
    required this.locks,
    this.deviceLocation,
    required this.distanceInfo,
    required this.isTracking,
    required this.countdown,
    this.isLoadingRoutes = false,
  });

  // Backward compatibility getter for single lock (gets the first lock)
  MapLocation? get lockLocation =>
      locks.isNotEmpty ? locks.first.location : null;

  // Get routes for all locks
  List<LatLng> get allDeviceToLockRoutes {
    return locks.expand((lock) => lock.deviceToLockRoute).toList();
  }

  List<LatLng> get allReceiverToLockRoutes {
    return locks.expand((lock) => lock.receiverToLockRoute).toList();
  }

  MapData copyWith({
    List<LockInfo>? locks,
    MapLocation? deviceLocation,
    String? distanceInfo,
    bool? isTracking,
    int? countdown,
    bool? isLoadingRoutes,
  }) {
    return MapData(
      locks: locks ?? this.locks,
      deviceLocation: deviceLocation ?? this.deviceLocation,
      distanceInfo: distanceInfo ?? this.distanceInfo,
      isTracking: isTracking ?? this.isTracking,
      countdown: countdown ?? this.countdown,
      isLoadingRoutes: isLoadingRoutes ?? this.isLoadingRoutes,
    );
  }

  @override
  String toString() {
    return 'MapData(locks: ${locks.length}, device: $deviceLocation, tracking: $isTracking)';
  }
}
