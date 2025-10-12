import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class OSRMService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1';
  final Dio _dio;

  OSRMService() : _dio = Dio() {
    // Configure Dio with better defaults
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<OSRMRouteResponse> getRoute({
    required LatLng start,
    required LatLng end,
    OSRMProfile profile = OSRMProfile.driving,
    List<LatLng>? waypoints,
  }) async {
    try {
      // Build coordinates string: start + waypoints + end
      final coordinates = StringBuffer();
      coordinates.write('${start.longitude},${start.latitude}');

      if (waypoints != null && waypoints.isNotEmpty) {
        for (final waypoint in waypoints) {
          coordinates.write(';${waypoint.longitude},${waypoint.latitude}');
        }
      }

      coordinates.write(';${end.longitude},${end.latitude}');

      final Map<String, dynamic> queryParams = {
        // 'overview': 'full',
        'geometries': 'geojson', // Use polyline for flexible polyline
        // 'steps': 'true',
        // 'annotations': 'true',
      };

      print('Fetching route from OSRM: $coordinates');

      final String url = '$_baseUrl/${profile.name}/$coordinates';

      //print url and query params
      print('OSRM URL: $url');
      print('Query Params: $queryParams');

      final response = await _dio.get(
        url,
        queryParameters: queryParams,
      );

      // print('OSRM Response: ${response.data}');
      print('OSRM Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Parsing OSRM response...');

        if (data == null) {
          throw Exception('OSRM response data is null');
        }

        if (data is! Map<String, dynamic>) {
          throw Exception(
              'OSRM response data is not a valid JSON object: ${data.runtimeType}');
        }

        // Check if response contains required fields
        if (data['code'] != 'Ok') {
          throw Exception(
              'OSRM service returned error: ${data['code']} - ${data['message'] ?? 'Unknown error'}');
        }

        if (data['routes'] == null) {
          throw Exception('OSRM response missing routes field');
        }

        return OSRMRouteResponse.fromJson(data);
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            'OSRM API error: ${e.response!.statusCode} - ${e.response!.statusMessage}');
      } else {
        throw Exception('OSRM API error: ${e.message}');
      }
    } catch (e) {
      throw Exception('OSRM service error: $e');
    }
  }

  Future<List<OSRMRouteResponse>> getMultipleRoutes({
    required LatLng start,
    required List<LatLng> destinations,
    OSRMProfile profile = OSRMProfile.driving,
  }) async {
    final List<OSRMRouteResponse> routes = [];

    for (final destination in destinations) {
      try {
        final route = await getRoute(
          start: start,
          end: destination,
          profile: profile,
        );
        routes.add(route);
      } catch (e) {
        print(
            'Failed to get route to ${destination.latitude}, ${destination.longitude}: $e');
        // Continue with other routes even if one fails
      }
    }

    return routes;
  }

  // Alternative method with more control
  Future<OSRMRouteResponse> getRouteWithOptions({
    required LatLng start,
    required LatLng end,
    OSRMProfile profile = OSRMProfile.driving,
    bool includeSteps = true,
    bool includeAnnotations = true,
  }) async {
    final coordinates =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

    final Map<String, dynamic> queryParams = {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': includeSteps.toString(),
      'annotations': includeAnnotations.toString(),
    };

    final String url = '$_baseUrl/${profile.name}/$coordinates';

    final response = await _dio.get(url, queryParameters: queryParams);

    if (response.statusCode == 200) {
      return OSRMRouteResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }

  void dispose() {
    _dio.close();
  }
}

class OSRMRouteResponse {
  final String code;
  final List<OSRMRoute> routes;
  final List<OSRMWaypoint> waypoints;

  OSRMRouteResponse({
    required this.code,
    required this.routes,
    required this.waypoints,
  });

  factory OSRMRouteResponse.fromJson(Map<String, dynamic> json) {
    return OSRMRouteResponse(
      code: json['code'] ?? 'Unknown',
      routes: (json['routes'] as List?)
              ?.map((route) => OSRMRoute.fromJson(route))
              .toList() ??
          [],
      waypoints: (json['waypoints'] as List?)
              ?.map((waypoint) => OSRMWaypoint.fromJson(waypoint))
              .toList() ??
          [],
    );
  }

  // Get the first route (usually the best one)
  OSRMRoute get firstRoute => routes.first;

  // Get polyline points for mapping
  List<LatLng> get polylinePoints {
    if (routes.isEmpty) return [];
    return routes.first.polylinePoints;
  }

  // Get total distance in meters
  double get totalDistance => routes.first.distance;

  // Get total duration in seconds
  double get totalDuration => routes.first.duration;

  bool get isSuccess => code == 'Ok';
}

class OSRMRoute {
  final double distance; // in meters
  final double duration; // in seconds
  final Map<String, dynamic>? geometry; // GeoJSON geometry object
  final double weight;
  final String? weightName;
  final List<OSRMLeg>? legs;

  OSRMRoute({
    required this.distance,
    required this.duration,
    this.geometry,
    required this.weight,
    this.weightName,
    this.legs,
  });

  factory OSRMRoute.fromJson(Map<String, dynamic> json) {
    return OSRMRoute(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      geometry: json['geometry'] as Map<String, dynamic>?,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      weightName: json['weight_name'],
      legs:
          (json['legs'] as List?)?.map((leg) => OSRMLeg.fromJson(leg)).toList(),
    );
  }

  // Parse GeoJSON geometry to LatLng points
  List<LatLng> get polylinePoints {
    if (geometry == null) return [];

    try {
      // Parse GeoJSON LineString coordinates
      if (geometry!['type'] == 'LineString') {
        final coordinates = geometry!['coordinates'] as List?;
        if (coordinates == null) return [];

        return coordinates
            .map((coord) {
              final coordList = coord as List;
              if (coordList.length >= 2) {
                final lng = (coordList[0] as num).toDouble();
                final lat = (coordList[1] as num).toDouble();
                return LatLng(lat, lng);
              }
              return null;
            })
            .where((point) => point != null)
            .cast<LatLng>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing GeoJSON geometry: $e');
      return [];
    }
  }

  // Get distance in kilometers
  double get distanceInKm => distance / 1000;

  // Get duration in minutes
  double get durationInMinutes => duration / 60;

  // Get formatted distance string
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Get formatted duration string
  String get formattedDuration {
    if (duration < 60) {
      return '${duration.round()} sec';
    } else if (duration < 3600) {
      return '${durationInMinutes.round()} min';
    } else {
      final hours = (duration / 3600).floor();
      final minutes = ((duration % 3600) / 60).round();
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}'.trim();
    }
  }

  // Get speed in km/h
  double get speedKmh {
    if (duration == 0) return 0;
    return (distanceInKm / (duration / 3600));
  }
}

class OSRMLeg {
  final double? distance;
  final double? duration;
  final double? weight;
  final String? summary;
  final List<OSRMRouteStep>? steps;

  OSRMLeg({
    this.distance,
    this.duration,
    this.weight,
    this.summary,
    this.steps,
  });

  factory OSRMLeg.fromJson(Map<String, dynamic> json) {
    return OSRMLeg(
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      summary: json['summary'],
      steps: (json['steps'] as List?)
          ?.map((step) => OSRMRouteStep.fromJson(step))
          .toList(),
    );
  }
}

class OSRMRouteStep {
  final double distance;
  final double duration;
  final String geometry;
  final String name;
  final String? instruction;
  final String? maneuverType;
  final List<int>? wayPoints;

  OSRMRouteStep({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.name,
    this.instruction,
    this.maneuverType,
    this.wayPoints,
  });

  factory OSRMRouteStep.fromJson(Map<String, dynamic> json) {
    return OSRMRouteStep(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      geometry: json['geometry'] ?? '',
      name: json['name'] ?? '',
      instruction: json['instruction'],
      maneuverType: json['maneuver']?['type'],
      wayPoints: json['way_points'] != null
          ? List<int>.from(json['way_points'] as List? ?? [])
          : null,
    );
  }

  List<LatLng> get polylinePoints {
    try {
      // Use regular polyline decoding for step geometry as well
      return _decodeRegularPolyline(geometry);
    } catch (e) {
      print('Error decoding step polyline: $e');
      return [];
    }
  }

  // Regular Google polyline decoding for steps
  List<LatLng> _decodeRegularPolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // Get maneuver icon based on type
  String? get maneuverIcon {
    if (maneuverType == null) return null;

    switch (maneuverType!) {
      case 'turn-left':
        return '↰';
      case 'turn-right':
        return '↱';
      case 'sharp left':
        return '↲';
      case 'sharp right':
        return '↳';
      case 'slight left':
        return '⬏';
      case 'slight right':
        return '⬎';
      case 'straight':
        return '↑';
      case 'uturn':
        return '↶';
      case 'arrive':
        return '⏏';
      case 'depart':
        return '⏎';
      default:
        return '→';
    }
  }
}

class OSRMWaypoint {
  final String name;
  final LatLng location;
  final double? distance;

  OSRMWaypoint({
    required this.name,
    required this.location,
    this.distance,
  });

  factory OSRMWaypoint.fromJson(Map<String, dynamic> json) {
    final locationList = json['location'] as List?;
    return OSRMWaypoint(
      name: json['name'] ?? '',
      location: locationList != null && locationList.length >= 2
          ? LatLng(
              (locationList[1] as num).toDouble(),
              (locationList[0] as num).toDouble(),
            )
          : const LatLng(0, 0),
      distance: json['distance'] != null
          ? (json['distance'] as num?)?.toDouble()
          : null,
    );
  }
}

enum OSRMProfile {
  driving('car'),
  walking('foot'),
  cycling('bike');

  const OSRMProfile(this.name);
  final String name;
}
