import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:location/location.dart';
import 'package:lockguard/feature/map/data/datasource/dummy.dart';
import '../../domain/repositories/map_repository.dart';
import '../models/map_location.dart';

class MapRepositoryImpl implements MapRepository {
  final String _firebaseUrl =
      "https://gps-lock-application-default-rtdb.asia-southeast1.firebasedatabase.app/gps.json";
  final Location _location = Location();
  // TODO: Enable real Firebase data by setting this to false
  // TODO: Test Firebase connectivity and data format
  final bool _useDummyData =
      true; // Switch between real and dummy data for LOCK only
  // Device location now always uses real GPS
  final Dio _dio = Dio();

  @override
  Future<MapLocation> fetchLockLocation() async {
    if (_useDummyData) {
      // Use dummy data
      final dummyData = await MapDummyData.generateDummyFirebaseData();
      return MapLocation.fromJson(dummyData);
    } else {
      // Use real Firebase data
      try {
        final response = await _dio.get(_firebaseUrl);
        if (response.statusCode == 200) {
          final data = response.data;
          return MapLocation.fromJson(data);
        } else {
          throw Exception('Failed to fetch location: ${response.statusCode}');
        }
      } catch (e) {
        // Fallback to dummy data on error
        final dummyData = await MapDummyData.generateDummyFirebaseData();
        return MapLocation.fromJson(dummyData);
      }
    }
  }

  @override
  Future<MapLocation?> fetchDeviceLocation() async {
    // Always use real GPS location for current device
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print("Location service not enabled");
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print("Location permission not granted");
          return null;
        }
      }

      print("Getting current device location...");
      final locationData = await _location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        print("Unable to get location coordinates");
        return null;
      }

      return MapLocation(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        lockStatus: "device",
        timestamp: DateTime.now(),
        deviceId:
            "CURRENT_DEVICE", // TODO: Get actual device ID from device_info_plus package
      );
    } catch (e) {
      print("Error getting device location: $e");
      // Return null instead of fallback to dummy data - device location should be real
      return null;
    }
  }

  @override
  Future<bool> updateLockStatus(String status) async {
    // Simulate API call to update lock status
    await Future.delayed(const Duration(milliseconds: 300));

    if (_useDummyData) {
      // For dummy data, just return success
      return true;
    } else {
      // Real implementation would call Firebase API
      try {
        // Implement actual Firebase update here
        return true;
      } catch (e) {
        return false;
      }
    }
  }
}
