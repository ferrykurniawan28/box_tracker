import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:lockguard/feature/map/data/datasource/dummy.dart';
import 'package:lockguard/core/services/osrm_services.dart';
import '../../../domain/repositories/map_repository.dart';
import '../../../data/models/map_location.dart';
import '../../../data/models/map_data.dart';

part 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final MapRepository _mapRepository;
  final OSRMService _osrmService;
  Timer? _trackingTimer;
  Timer? _countdownTimer;

  // TODO: Update receiver location as needed
  static const LatLng receiverLocation = LatLng(-6.218987, 106.801851);

  MapCubit(this._mapRepository, this._osrmService) : super(MapInitial());

  Future<void> initializeMap() async {
    emit(MapLoading());

    try {
      final lockLocations = await _mapRepository.fetchLockLocations();
      final deviceLocation = await _mapRepository.fetchDeviceLocation();

      // Convert lock locations to LockInfo objects
      final locks = lockLocations
          .map((lockLocation) => LockInfo(
                location: lockLocation,
              ))
          .toList();

      // Calculate distance to the nearest lock for display
      final distanceInfo = locks.isNotEmpty
          ? _calculateDistance(
              locks.first.location,
              deviceLocation ?? MapDummyData.initialMapData.deviceLocation!,
            )
          : "No locks available";

      // Create initial MapData with multiple locks
      final mapData = MapData(
        locks: locks,
        deviceLocation: deviceLocation,
        distanceInfo: distanceInfo,
        isTracking: false,
        countdown: 0,
      );

      emit(MapDataLoaded(mapData: mapData));

      // Load routes automatically for all locks
      await _loadRoutes();
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }

  Future<void> fetchLockLocation() async {
    try {
      final currentState = state;
      if (currentState is MapDataLoaded) {
        final lockLocations = await _mapRepository.fetchLockLocations();
        final deviceLocation = currentState.mapData.deviceLocation;

        // Convert to LockInfo objects
        final locks = lockLocations
            .map((lockLocation) => LockInfo(
                  location: lockLocation,
                ))
            .toList();

        final distanceInfo = locks.isNotEmpty
            ? _calculateDistance(
                locks.first.location,
                deviceLocation ?? MapDummyData.initialMapData.deviceLocation!,
              )
            : "No locks available";

        emit(currentState.copyWith(
          mapData: currentState.mapData.copyWith(
            locks: locks,
            distanceInfo: distanceInfo,
          ),
        ));

        // Reload routes when lock locations change
        await _loadRoutes();
      }
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }

  // TODO: Implement real device GPS location using location package
  // TODO: Add location permissions handling (location.requestPermission())
  // TODO: Use Location().getLocation() to get actual device coordinates
  // TODO: Handle location service enabling and permission status
  Future<void> fetchDeviceLocation() async {
    try {
      final currentState = state;
      if (currentState is MapDataLoaded) {
        final deviceLocation = await _mapRepository.fetchDeviceLocation();
        final lockLocation = currentState.mapData.lockLocation;

        final distanceInfo = _calculateDistance(lockLocation!,
            deviceLocation ?? MapDummyData.initialMapData.deviceLocation!);

        emit(currentState.copyWith(
          mapData: currentState.mapData.copyWith(
            deviceLocation: deviceLocation,
            distanceInfo: distanceInfo,
          ),
        ));

        // Reload routes when device location changes
        await _loadRoutes();
      }
    } catch (e) {
      print("Error fetching device location: $e");
    }
  }

  String _calculateDistance(
      MapLocation lockLocation, MapLocation deviceLocation) {
    final lockLatLng = LatLng(lockLocation.latitude, lockLocation.longitude);
    final deviceLatLng =
        LatLng(deviceLocation.latitude, deviceLocation.longitude);

    // Calculate distance from device to lock (not receiver to lock)
    final distance = Distance().as(
      LengthUnit.Kilometer,
      deviceLatLng,
      lockLatLng,
    );

    return "Distance: ${distance.toStringAsFixed(2)} km";
  }

  Future<void> _loadRoutes() async {
    final currentState = state;
    if (currentState is! MapDataLoaded) return;

    final locks = currentState.mapData.locks;
    final deviceLocation = currentState.mapData.deviceLocation;

    // Set loading state
    emit(currentState.copyWith(
      mapData: currentState.mapData.copyWith(
        isLoadingRoutes: true,
      ),
    ));

    try {
      List<LockInfo> updatedLocks = [];

      // Calculate routes for each lock
      for (final lockInfo in locks) {
        List<LatLng> deviceToLockRoute = [];
        List<LatLng> receiverToLockRoute = [];

        final lockLatLng =
            LatLng(lockInfo.location.latitude, lockInfo.location.longitude);

        // Get route from receiver to this lock location
        try {
          final receiverRoute = await _osrmService.getRoute(
            start: receiverLocation,
            end: lockLatLng,
          );
          receiverToLockRoute = receiverRoute.routes.first.polylinePoints;
        } catch (e) {
          print(
              "Error getting receiver route to ${lockInfo.location.deviceId}: $e");
        }

        // Get route from device to this lock location (if device location is available)
        if (deviceLocation != null) {
          try {
            final deviceLatLng =
                LatLng(deviceLocation.latitude, deviceLocation.longitude);
            final deviceRoute = await _osrmService.getRoute(
              start: deviceLatLng,
              end: lockLatLng,
            );
            deviceToLockRoute = deviceRoute.routes.first.polylinePoints;
          } catch (e) {
            print(
                "Error getting device route to ${lockInfo.location.deviceId}: $e");
          }
        }

        // Create updated lock info with routes
        updatedLocks.add(lockInfo.copyWith(
          deviceToLockRoute: deviceToLockRoute,
          receiverToLockRoute: receiverToLockRoute,
        ));
      }

      print("Loaded routes for ${updatedLocks.length} locks");

      // Update state with locks containing routes and clear loading state
      emit(currentState.copyWith(
        mapData: currentState.mapData.copyWith(
          locks: updatedLocks,
          isLoadingRoutes: false,
        ),
      ));
    } catch (e) {
      print("Error loading routes: $e");
      // Clear loading state even on error
      emit(currentState.copyWith(
        mapData: currentState.mapData.copyWith(
          isLoadingRoutes: false,
        ),
      ));
    }
  }

  void toggleTracking() {
    final currentState = state;
    if (currentState is MapDataLoaded) {
      if (currentState.mapData.isTracking) {
        _stopTracking();
      } else {
        _startTracking();
      }
    }
  }

  void _startTracking() {
    final currentState = state;
    if (currentState is MapDataLoaded) {
      emit(currentState.copyWith(
        mapData: currentState.mapData.copyWith(
          isTracking: true,
          countdown: 15,
        ),
      ));

      // Fetch immediately
      fetchLockLocation();
      fetchDeviceLocation();

      _trackingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        fetchLockLocation();
        fetchDeviceLocation();

        final updatedState = state;
        if (updatedState is MapDataLoaded) {
          emit(updatedState.copyWith(
            mapData: updatedState.mapData.copyWith(countdown: 15),
          ));
        }
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentTimerState = state;
        if (currentTimerState is MapDataLoaded) {
          final currentCountdown = currentTimerState.mapData.countdown;
          if (currentCountdown > 0) {
            emit(currentTimerState.copyWith(
              mapData: currentTimerState.mapData.copyWith(
                countdown: currentCountdown - 1,
              ),
            ));
          }
        }
      });
    }
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    _countdownTimer?.cancel();

    final currentState = state;
    if (currentState is MapDataLoaded) {
      emit(currentState.copyWith(
        mapData: currentState.mapData.copyWith(
          isTracking: false,
          countdown: 0,
        ),
      ));
    }
  }

  Future<void> updateLockStatus(String lockId, String status) async {
    try {
      final success = await _mapRepository.updateLockStatus(lockId, status);
      if (success) {
        // Refresh the lock locations to get updated status
        await fetchLockLocation();
      }
    } catch (e) {
      emit(MapError("Failed to update lock status: $e"));
    }
  }

  @override
  Future<void> close() {
    _trackingTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
