class MapLocation {
  final double latitude;
  final double longitude;
  final String lockStatus;
  final DateTime timestamp;
  final String? deviceId; // Device identifier for tracking multiple devices

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.lockStatus,
    required this.timestamp,
    this.deviceId,
  });

  factory MapLocation.fromJson(Map<String, dynamic> json) {
    return MapLocation(
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      lockStatus: json['lock']?.toString() ?? "Unknown",
      timestamp: DateTime.now(),
      deviceId: json['deviceId']?.toString(), // Parse device ID from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'lock': lockStatus,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId, // Include device ID in JSON
    };
  }

  MapLocation copyWith({
    double? latitude,
    double? longitude,
    String? lockStatus,
    DateTime? timestamp,
    String? deviceId,
  }) {
    return MapLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lockStatus: lockStatus ?? this.lockStatus,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  String toString() {
    return 'MapLocation(lat: $latitude, lng: $longitude, status: $lockStatus, deviceId: $deviceId)';
  }
}
