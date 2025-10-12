import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/repositories/map_repository.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final MapRepository _mapRepository;
  Timer? _updateTimer;
  Timer? _countdownTimer;

  // Real device location coordinates (will be updated from GPS)
  LatLng? _currentDeviceLocation;

  HistoryCubit(this._mapRepository) : super(HistoryInitial());

  Future<void> initializeHistory() async {
    emit(HistoryLoading());

    try {
      // Initialize with empty history data
      emit(HistoryLoaded(
        historyData: [],
        isAutoUpdating: false,
        countdown: 0,
        locationInfo: "Waiting for location...",
        lockStatus: "Unknown",
        lastUpdated: "Never",
        distanceInfo: "Calculating...",
      ));

      // Get current device location from GPS for distance calculation
      await _getCurrentDeviceLocation();
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _getCurrentDeviceLocation() async {
    // Get real device location from GPS (same as used in map)
    final deviceLocation = await _mapRepository.fetchDeviceLocation();
    if (deviceLocation != null) {
      _currentDeviceLocation =
          LatLng(deviceLocation.latitude, deviceLocation.longitude);
      print(
          "Updated current device location: ${deviceLocation.latitude}, ${deviceLocation.longitude}");
    } else {
      print("Could not get current device location");
    }
  }

  Future<void> fetchLiveTrackingData() async {
    try {
      final currentState = state;
      if (currentState is HistoryLoaded) {
        // Fetch lock location from repository (same as map feature)
        final lockLocation = await _mapRepository.fetchLockLocation();

        // Update current device location for distance calculation
        await _getCurrentDeviceLocation();

        // Calculate distance
        String distanceInfo = "Current device location not available.";
        if (_currentDeviceLocation != null) {
          final lockLatLng =
              LatLng(lockLocation.latitude, lockLocation.longitude);
          final distance = Distance().as(
            LengthUnit.Kilometer,
            _currentDeviceLocation!,
            lockLatLng,
          );
          distanceInfo = "Distance: ${distance.toStringAsFixed(2)} km";
        }

        final locationInfo =
            "Latitude: ${lockLocation.latitude}, Longitude: ${lockLocation.longitude}";
        final lockStatus = lockLocation.lockStatus;
        final lastUpdated = DateTime.now().toLocal().toString().split('.')[0];

        // Create new history entry
        final newEntry = HistoryEntry(
          location: locationInfo,
          lockStatus: lockStatus,
          lastUpdated: lastUpdated,
          distance: distanceInfo,
          timestamp: DateTime.now(),
          deviceId: lockLocation.deviceId, // Include device ID for tracking
        );

        // Add to history (insert at beginning for latest first)
        final updatedHistory = [newEntry, ...currentState.historyData];

        emit(currentState.copyWith(
          historyData: updatedHistory,
          locationInfo: locationInfo,
          lockStatus: lockStatus,
          lastUpdated: lastUpdated,
          distanceInfo: distanceInfo,
        ));
      }
    } catch (e) {
      emit(HistoryError("Error fetching location: $e"));
    }
  }

  void toggleAutoUpdate() {
    final currentState = state;
    if (currentState is HistoryLoaded) {
      if (currentState.isAutoUpdating) {
        _stopAutoUpdate();
      } else {
        _startAutoUpdate();
      }
    }
  }

  void _startAutoUpdate() {
    final currentState = state;
    if (currentState is HistoryLoaded) {
      emit(currentState.copyWith(
        isAutoUpdating: true,
        countdown: 15,
      ));

      // Fetch immediately
      fetchLiveTrackingData();

      _updateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        fetchLiveTrackingData();

        final updatedState = state;
        if (updatedState is HistoryLoaded) {
          emit(updatedState.copyWith(countdown: 15));
        }
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentTimerState = state;
        if (currentTimerState is HistoryLoaded) {
          final currentCountdown = currentTimerState.countdown;
          if (currentCountdown > 0) {
            emit(currentTimerState.copyWith(
              countdown: currentCountdown - 1,
            ));
          }
        }
      });
    }
  }

  void _stopAutoUpdate() {
    _updateTimer?.cancel();
    _countdownTimer?.cancel();

    final currentState = state;
    if (currentState is HistoryLoaded) {
      emit(currentState.copyWith(
        isAutoUpdating: false,
        countdown: 0,
      ));
    }
  }

  @override
  Future<void> close() {
    _updateTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
