import 'package:firebase_database/firebase_database.dart';
import '../models/map_location.dart';

/// Service for handling Firebase Realtime Database operations
/// Database structure expected:
/// - /locks/{lockId} - individual lock data
/// - /receivers/{receiverId} - receiver station data
/// - /history/{lockId}/{timestamp} - historical events for locks
class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Fetch all lock locations from Firebase
  /// Expected structure: /locks/{lockId}
  /// Each lock should have: latitude, longitude, lock (status), timestamp, deviceId
  Future<List<MapLocation>> fetchLocks() async {
    try {
      final snapshot = await _database.child('locks').get();

      if (!snapshot.exists) {
        print('No locks found in Firebase');
        return [];
      }

      final locks = <MapLocation>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final lockData = Map<String, dynamic>.from(value as Map);
          locks.add(MapLocation.fromJson(lockData));
        } catch (e) {
          print('Error parsing lock $key: $e');
        }
      });

      print('Fetched ${locks.length} locks from Firebase');
      return locks;
    } catch (e) {
      print('Error fetching locks from Firebase: $e');
      rethrow;
    }
  }

  /// Fetch a single lock location by ID
  Future<MapLocation?> fetchLockById(String lockId) async {
    try {
      final snapshot = await _database.child('locks/$lockId').get();

      if (!snapshot.exists) {
        print('Lock $lockId not found in Firebase');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return MapLocation.fromJson(data);
    } catch (e) {
      print('Error fetching lock $lockId: $e');
      return null;
    }
  }

  /// Fetch all receiver locations from Firebase
  /// Expected structure: /receivers/{receiverId}
  /// Each receiver should have: latitude, longitude, timestamp, deviceId
  Future<List<MapLocation>> fetchReceivers() async {
    try {
      final snapshot = await _database.child('receivers').get();

      if (!snapshot.exists) {
        print('No receivers found in Firebase');
        return [];
      }

      final receivers = <MapLocation>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final receiverData = Map<String, dynamic>.from(value as Map);
          // Ensure lockStatus is set to "receiver" for identification
          receiverData['lock'] = receiverData['lock'] ?? 'receiver';
          receivers.add(MapLocation.fromJson(receiverData));
        } catch (e) {
          print('Error parsing receiver $key: $e');
        }
      });

      print('Fetched ${receivers.length} receivers from Firebase');
      return receivers;
    } catch (e) {
      print('Error fetching receivers from Firebase: $e');
      rethrow;
    }
  }

  /// Fetch historical location data for a specific lock
  /// Expected structure: /history/{lockId}/{timestamp}
  /// Returns list of historical MapLocation entries sorted by timestamp (newest first)
  Future<List<MapLocation>> fetchLockHistory(String lockId,
      {int limit = 50}) async {
    try {
      final snapshot = await _database
          .child('history/$lockId')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .get();

      if (!snapshot.exists) {
        print('No history found for lock $lockId');
        return [];
      }

      final history = <MapLocation>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final historyData = Map<String, dynamic>.from(value as Map);
          history.add(MapLocation.fromJson(historyData));
        } catch (e) {
          print('Error parsing history entry $key: $e');
        }
      });

      // Sort by timestamp descending (newest first)
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('Fetched ${history.length} history entries for lock $lockId');
      return history;
    } catch (e) {
      print('Error fetching history for lock $lockId: $e');
      rethrow;
    }
  }

  /// Fetch all history entries across all locks
  /// Returns combined history from all locks sorted by timestamp (newest first)
  Future<List<MapLocation>> fetchAllHistory({int limitPerLock = 20}) async {
    try {
      // First get all lock IDs
      final locksSnapshot = await _database.child('locks').get();

      if (!locksSnapshot.exists) {
        print('No locks found, cannot fetch history');
        return [];
      }

      final allHistory = <MapLocation>[];
      final locksData = locksSnapshot.value as Map<dynamic, dynamic>;

      // Fetch history for each lock
      for (final lockId in locksData.keys) {
        final lockHistory =
            await fetchLockHistory(lockId.toString(), limit: limitPerLock);
        allHistory.addAll(lockHistory);
      }

      // Sort all combined history by timestamp descending
      allHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print(
          'Fetched ${allHistory.length} total history entries from all locks');
      return allHistory;
    } catch (e) {
      print('Error fetching all history: $e');
      rethrow;
    }
  }

  /// Update lock status in Firebase
  Future<bool> updateLockStatus(String lockId, String status) async {
    try {
      await _database.child('locks/$lockId').update({
        'lock': status,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Updated lock $lockId status to: $status');
      return true;
    } catch (e) {
      print('Error updating lock status: $e');
      return false;
    }
  }

  /// Listen to real-time updates for a specific lock
  Stream<MapLocation?> listenToLock(String lockId) {
    return _database.child('locks/$lockId').onValue.map((event) {
      if (!event.snapshot.exists) return null;

      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return MapLocation.fromJson(data);
      } catch (e) {
        print('Error parsing lock update: $e');
        return null;
      }
    });
  }

  /// Listen to real-time updates for all locks
  Stream<List<MapLocation>> listenToAllLocks() {
    return _database.child('locks').onValue.map((event) {
      if (!event.snapshot.exists) return <MapLocation>[];

      final locks = <MapLocation>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final lockData = Map<String, dynamic>.from(value as Map);
          locks.add(MapLocation.fromJson(lockData));
        } catch (e) {
          print('Error parsing lock $key: $e');
        }
      });

      return locks;
    });
  }

  /// Listen to real-time updates for receivers
  Stream<List<MapLocation>> listenToReceivers() {
    return _database.child('receivers').onValue.map((event) {
      if (!event.snapshot.exists) return <MapLocation>[];

      final receivers = <MapLocation>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final receiverData = Map<String, dynamic>.from(value as Map);
          receiverData['lock'] = receiverData['lock'] ?? 'receiver';
          receivers.add(MapLocation.fromJson(receiverData));
        } catch (e) {
          print('Error parsing receiver $key: $e');
        }
      });

      return receivers;
    });
  }
}
