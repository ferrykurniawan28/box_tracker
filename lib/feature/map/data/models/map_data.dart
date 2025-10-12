import 'package:lockguard/feature/map/data/models/map_location.dart';
import 'package:latlong2/latlong.dart';

class LockInfo {
  final MapLocation location;
  final List<LatLng> deviceToLockRoute; // Route from device to this lock
  final Map<String, List<LatLng>>
      receiverToLockRoutes; // Routes from multiple receivers to this lock

  const LockInfo({
    required this.location,
    this.deviceToLockRoute = const [],
    this.receiverToLockRoutes = const {}, // Map of receiver ID to route points
  });

  // Backward compatibility getter
  List<LatLng> get receiverToLockRoute {
    if (receiverToLockRoutes.isEmpty) return [];
    return receiverToLockRoutes.values.first;
  }

  LockInfo copyWith({
    MapLocation? location,
    List<LatLng>? deviceToLockRoute,
    Map<String, List<LatLng>>? receiverToLockRoutes,
  }) {
    return LockInfo(
      location: location ?? this.location,
      deviceToLockRoute: deviceToLockRoute ?? this.deviceToLockRoute,
      receiverToLockRoutes: receiverToLockRoutes ?? this.receiverToLockRoutes,
    );
  }

  @override
  String toString() {
    return 'LockInfo(location: $location, deviceRoute: ${deviceToLockRoute.length} points, receiverRoutes: ${receiverToLockRoutes.length} receivers)';
  }
}

class MapData {
  final List<LockInfo> locks;
  final List<MapLocation> receivers; // NEW: Multiple receivers support
  final MapLocation? deviceLocation;
  final String distanceInfo;
  final bool isTracking;
  final int countdown;
  final bool isLoadingRoutes;

  const MapData({
    required this.locks,
    this.receivers = const [], // NEW: Default empty receivers list
    this.deviceLocation,
    required this.distanceInfo,
    required this.isTracking,
    required this.countdown,
    this.isLoadingRoutes = false,
  });

  // Backward compatibility getter for single lock (gets the first lock)
  MapLocation? get lockLocation =>
      locks.isNotEmpty ? locks.first.location : null;

  // Backward compatibility getter for single receiver (gets the first receiver)
  MapLocation? get receiverLocation =>
      receivers.isNotEmpty ? receivers.first : null;

  // Get routes for all locks
  List<LatLng> get allDeviceToLockRoutes {
    return locks.expand((lock) => lock.deviceToLockRoute).toList();
  }

  List<LatLng> get allReceiverToLockRoutes {
    return locks
        .expand(
            (lock) => lock.receiverToLockRoutes.values.expand((route) => route))
        .toList();
  }

  MapData copyWith({
    List<LockInfo>? locks,
    List<MapLocation>? receivers, // NEW: receivers parameter
    MapLocation? deviceLocation,
    String? distanceInfo,
    bool? isTracking,
    int? countdown,
    bool? isLoadingRoutes,
  }) {
    return MapData(
      locks: locks ?? this.locks,
      receivers: receivers ?? this.receivers, // NEW: include receivers
      deviceLocation: deviceLocation ?? this.deviceLocation,
      distanceInfo: distanceInfo ?? this.distanceInfo,
      isTracking: isTracking ?? this.isTracking,
      countdown: countdown ?? this.countdown,
      isLoadingRoutes: isLoadingRoutes ?? this.isLoadingRoutes,
    );
  }

  @override
  String toString() {
    return 'MapData(locks: ${locks.length}, receivers: ${receivers.length}, device: $deviceLocation, tracking: $isTracking)';
  }
}
