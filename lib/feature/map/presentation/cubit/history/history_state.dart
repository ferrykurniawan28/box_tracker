part of 'history_cubit.dart';

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<HistoryEntry> historyData;
  final bool isAutoUpdating;
  final int countdown;
  final String locationInfo;
  final String lockStatus;
  final String lastUpdated;
  final String distanceInfo;

  HistoryLoaded({
    required this.historyData,
    required this.isAutoUpdating,
    required this.countdown,
    required this.locationInfo,
    required this.lockStatus,
    required this.lastUpdated,
    required this.distanceInfo,
  });

  HistoryLoaded copyWith({
    List<HistoryEntry>? historyData,
    bool? isAutoUpdating,
    int? countdown,
    String? locationInfo,
    String? lockStatus,
    String? lastUpdated,
    String? distanceInfo,
  }) {
    return HistoryLoaded(
      historyData: historyData ?? this.historyData,
      isAutoUpdating: isAutoUpdating ?? this.isAutoUpdating,
      countdown: countdown ?? this.countdown,
      locationInfo: locationInfo ?? this.locationInfo,
      lockStatus: lockStatus ?? this.lockStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      distanceInfo: distanceInfo ?? this.distanceInfo,
    );
  }
}

class HistoryError extends HistoryState {
  final String message;

  HistoryError(this.message);
}

class HistoryEntry {
  final String location;
  final String lockStatus;
  final String lastUpdated;
  final String distance;
  final DateTime timestamp;
  final String? deviceId; // Device identifier for tracking

  HistoryEntry({
    required this.location,
    required this.lockStatus,
    required this.lastUpdated,
    required this.distance,
    required this.timestamp,
    this.deviceId,
  });

  Map<String, String> toMap() {
    return {
      'location': location,
      'lockStatus': lockStatus,
      'lastUpdated': lastUpdated,
      'distance': distance,
      'deviceId': deviceId ?? '',
    };
  }
}
