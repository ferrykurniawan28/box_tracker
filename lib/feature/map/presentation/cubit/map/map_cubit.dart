import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
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

  MapCubit(this._mapRepository, this._osrmService) : super(MapInitial());

  Future<void> initializeMap() async {
    emit(MapLoading());

    try {
      final lockLocations = await _mapRepository.fetchLockLocations();
      final receiverLocations =
          await _mapRepository.fetchReceiverLocations(); // NEW: Fetch receivers
      final deviceLocation = await _mapRepository.fetchDeviceLocation();

      // Convert lock locations to LockInfo objects
      final locks = lockLocations
          .map((lockLocation) => LockInfo(
                location: lockLocation,
              ))
          .toList();

      // Calculate distance to the nearest lock for display
      String distanceInfo;
      if (locks.isEmpty) {
        distanceInfo = "No locks available";
      } else if (deviceLocation == null) {
        distanceInfo = "Waiting for device location...";
      } else {
        distanceInfo = _calculateDistance(locks.first.location, deviceLocation);
      }

      // Create initial MapData with multiple locks and receivers
      final mapData = MapData(
        locks: locks,
        receivers: receiverLocations, // NEW: Include receivers
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

        String distanceInfo;
        if (locks.isEmpty) {
          distanceInfo = "No locks available";
        } else if (deviceLocation == null) {
          distanceInfo = "Waiting for device location...";
        } else {
          distanceInfo =
              _calculateDistance(locks.first.location, deviceLocation);
        }

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

  Future<void> fetchDeviceLocation() async {
    try {
      final currentState = state;
      if (currentState is MapDataLoaded) {
        final deviceLocation = await _mapRepository.fetchDeviceLocation();
        final lockLocation = currentState.mapData.lockLocation;

        String distanceInfo;
        if (lockLocation == null) {
          distanceInfo = "No lock selected";
        } else if (deviceLocation == null) {
          distanceInfo = "Waiting for device location...";
        } else {
          distanceInfo = _calculateDistance(lockLocation, deviceLocation);
        }

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
    final receivers = currentState.mapData.receivers;
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
        Map<String, List<LatLng>> receiverToLockRoutes = {};

        final lockLatLng =
            LatLng(lockInfo.location.latitude, lockInfo.location.longitude);

        // Get routes from ALL receivers to this lock location
        for (final receiver in receivers) {
          try {
            final receiverLatLng =
                LatLng(receiver.latitude, receiver.longitude);
            final receiverId =
                receiver.deviceId ?? "RECEIVER_${receivers.indexOf(receiver)}";

            final receiverRoute = await _osrmService.getRoute(
              start: receiverLatLng,
              end: lockLatLng,
            );

            receiverToLockRoutes[receiverId] =
                receiverRoute.routes.first.polylinePoints;
            print(
                "Loaded route from $receiverId to ${lockInfo.location.deviceId}");
          } catch (e) {
            print(
                "Error getting route from ${receiver.deviceId} to ${lockInfo.location.deviceId}: $e");
          }
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
          receiverToLockRoutes: receiverToLockRoutes,
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
