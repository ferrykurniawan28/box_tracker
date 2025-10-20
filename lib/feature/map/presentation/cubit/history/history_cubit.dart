import 'dart:async';
import 'dart:math';
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
      // Fetch all history from Firebase
      final allHistory = await _mapRepository.fetchAllHistory(limitPerLock: 20);

      // Convert MapLocation history to HistoryEntry
      final historyEntries = allHistory.map((location) {
        // Calculate distance if we have device location
        String distanceInfo = "Calculating...";
        if (_currentDeviceLocation != null) {
          final lockLatLng = LatLng(location.latitude, location.longitude);
          final distance = Distance().as(
            LengthUnit.Kilometer,
            _currentDeviceLocation!,
            lockLatLng,
          );
          distanceInfo = "Distance: ${distance.toStringAsFixed(2)} km";
        }

        final locationInfo =
            "Latitude: ${location.latitude}, Longitude: ${location.longitude}";

        // Determine if there's an image path (for unlocked status)
        String? imagePath;
        bool isAuthorized = true;

        // If unlocked, show facial recognition image
        if (location.lockStatus == "unlocked") {
          // Use random image for now - in production, this would come from Firebase
          final random = Random();
          final imageNumber = random.nextInt(4) + 1;
          imagePath = 'assets/images/sucess-$imageNumber.jpeg';
          isAuthorized = true;
        }

        return HistoryEntry(
          location: locationInfo,
          lockStatus: location.lockStatus,
          lastUpdated: location.timestamp.toLocal().toString().split('.')[0],
          distance: distanceInfo,
          timestamp: location.timestamp,
          deviceId: location.deviceId,
          isAuthorized: isAuthorized,
          imagePath: imagePath,
        );
      }).toList();

      emit(HistoryLoaded(
        historyData: historyEntries,
        isAutoUpdating: false,
        countdown: 0,
        locationInfo: historyEntries.isNotEmpty
            ? historyEntries.first.location
            : "No history",
        lockStatus: historyEntries.isNotEmpty
            ? historyEntries.first.lockStatus
            : "Unknown",
        lastUpdated: historyEntries.isNotEmpty
            ? historyEntries.first.lastUpdated
            : "Never",
        distanceInfo:
            historyEntries.isNotEmpty ? historyEntries.first.distance : "N/A",
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
        // Fetch latest lock location from repository
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

        // Determine if there's an image path (for unlocked status)
        String? imagePath;
        bool isAuthorized = true;

        // If unlocked, show facial recognition image
        if (lockStatus == "unlocked") {
          // Use random image for now - in production, this would come from Firebase
          final random = Random();
          final imageNumber = random.nextInt(4) + 1;
          imagePath = 'assets/images/sucess-$imageNumber.jpeg';
          isAuthorized = true;
        }

        // Create new history entry from real Firebase data
        final newEntry = HistoryEntry(
          location: locationInfo,
          lockStatus: lockStatus,
          lastUpdated: lastUpdated,
          distance: distanceInfo,
          timestamp: lockLocation.timestamp,
          deviceId: lockLocation.deviceId,
          isAuthorized: isAuthorized,
          imagePath: imagePath,
        );

        // Check if this entry is different from the last one to avoid duplicates
        bool isDifferent = true;
        if (currentState.historyData.isNotEmpty) {
          final lastEntry = currentState.historyData.first;
          // Compare key fields to determine if it's a new event
          isDifferent = lastEntry.lockStatus != newEntry.lockStatus ||
              lastEntry.location != newEntry.location ||
              lastEntry.timestamp
                      .difference(newEntry.timestamp)
                      .inSeconds
                      .abs() >
                  5;
        }

        // Only add if it's different from the last entry
        final updatedHistory = isDifferent
            ? [newEntry, ...currentState.historyData]
            : currentState.historyData;

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
