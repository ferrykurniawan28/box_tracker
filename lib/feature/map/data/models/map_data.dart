import 'package:lockguard/feature/map/data/models/map_location.dart';
import 'package:latlong2/latlong.dart';

class MapData {
  final MapLocation lockLocation;
  final MapLocation? deviceLocation;
  final String distanceInfo;
  final bool isTracking;
  final int countdown;
  final List<LatLng> deviceToLockRoute; // Route from device to lock
  final List<LatLng> receiverToLockRoute; // Route from receiver to lock

  const MapData({
    required this.lockLocation,
    this.deviceLocation,
    required this.distanceInfo,
    required this.isTracking,
    required this.countdown,
    this.deviceToLockRoute = const [],
    this.receiverToLockRoute = const [],
  });

  MapData copyWith({
    MapLocation? lockLocation,
    MapLocation? deviceLocation,
    String? distanceInfo,
    bool? isTracking,
    int? countdown,
    List<LatLng>? deviceToLockRoute,
    List<LatLng>? receiverToLockRoute,
  }) {
    return MapData(
      lockLocation: lockLocation ?? this.lockLocation,
      deviceLocation: deviceLocation ?? this.deviceLocation,
      distanceInfo: distanceInfo ?? this.distanceInfo,
      isTracking: isTracking ?? this.isTracking,
      countdown: countdown ?? this.countdown,
      deviceToLockRoute: deviceToLockRoute ?? this.deviceToLockRoute,
      receiverToLockRoute: receiverToLockRoute ?? this.receiverToLockRoute,
    );
  }

  @override
  String toString() {
    return 'MapData(lock: $lockLocation, device: $deviceLocation, tracking: $isTracking)';
  }
}
