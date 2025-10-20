# Firebase Realtime Database Structure

This document describes the expected Firebase Realtime Database structure for the LockGuard application.

## Database URL
The app connects to: `https://gps-lock-application-default-rtdb.asia-southeast1.firebasedatabase.app/`

## Database Structure

### 1. Locks Collection (`/locks`)

Stores information about all lock devices in the system.

**Path:** `/locks/{lockId}`

**Fields:**
- `latitude` (double): Lock device latitude coordinate
- `longitude` (double): Lock device longitude coordinate  
- `lock` (string): Current lock status - "locked" or "unlocked"
- `timestamp` (string): ISO 8601 timestamp of last update (e.g., "2025-10-20T14:30:00.000Z")
- `deviceId` (string): Unique identifier for the lock device (e.g., "LOCK_001")

**Example:**
```json
{
  "locks": {
    "LOCK_001": {
      "latitude": -6.2088,
      "longitude": 106.8456,
      "lock": "locked",
      "timestamp": "2025-10-20T14:30:00.000Z",
      "deviceId": "LOCK_001"
    },
    "LOCK_002": {
      "latitude": -6.1751,
      "longitude": 106.8650,
      "lock": "unlocked",
      "timestamp": "2025-10-20T14:35:00.000Z",
      "deviceId": "LOCK_002"
    }
  }
}
```

### 2. Receivers Collection (`/receivers`)

Stores information about receiver stations that can communicate with locks.

**Path:** `/receivers/{receiverId}`

**Fields:**
- `latitude` (double): Receiver station latitude coordinate
- `longitude` (double): Receiver station longitude coordinate
- `lock` (string): Should be "receiver" to identify as a receiver station
- `timestamp` (string): ISO 8601 timestamp of last update
- `deviceId` (string): Unique identifier for the receiver (e.g., "RECEIVER_001")

**Example:**
```json
{
  "receivers": {
    "RECEIVER_001": {
      "latitude": -6.218987,
      "longitude": 106.801851,
      "lock": "receiver",
      "timestamp": "2025-10-20T14:00:00.000Z",
      "deviceId": "RECEIVER_001"
    },
    "RECEIVER_002": {
      "latitude": -6.200000,
      "longitude": 106.816666,
      "lock": "receiver",
      "timestamp": "2025-10-20T14:00:00.000Z",
      "deviceId": "RECEIVER_002"
    }
  }
}
```

### 3. History Collection (`/history`)

Stores historical location and status data for each lock device.

**Path:** `/history/{lockId}/{eventId}`

**Fields:**
- `latitude` (double): Lock latitude at the time of event
- `longitude` (double): Lock longitude at the time of event
- `lock` (string): Lock status at the time - "locked" or "unlocked"
- `timestamp` (string): ISO 8601 timestamp of the event
- `deviceId` (string): Lock device identifier
- `imagePath` (string, optional): Path to facial recognition image (if unlock event)

**Example:**
```json
{
  "history": {
    "LOCK_001": {
      "event_1729432800": {
        "latitude": -6.2088,
        "longitude": 106.8456,
        "lock": "unlocked",
        "timestamp": "2025-10-20T14:00:00.000Z",
        "deviceId": "LOCK_001",
        "imagePath": "images/face_capture_123.jpg"
      },
      "event_1729433400": {
        "latitude": -6.2088,
        "longitude": 106.8456,
        "lock": "locked",
        "timestamp": "2025-10-20T14:10:00.000Z",
        "deviceId": "LOCK_001"
      }
    },
    "LOCK_002": {
      "event_1729432900": {
        "latitude": -6.1751,
        "longitude": 106.8650,
        "lock": "unlocked",
        "timestamp": "2025-10-20T14:01:30.000Z",
        "deviceId": "LOCK_002",
        "imagePath": "images/face_capture_124.jpg"
      }
    }
  }
}
```

## Firebase Rules

Recommended security rules for the database:

```json
{
  "rules": {
    "locks": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$lockId": {
        ".validate": "newData.hasChildren(['latitude', 'longitude', 'lock', 'timestamp', 'deviceId'])"
      }
    },
    "receivers": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$receiverId": {
        ".validate": "newData.hasChildren(['latitude', 'longitude', 'timestamp', 'deviceId'])"
      }
    },
    "history": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$lockId": {
        "$eventId": {
          ".validate": "newData.hasChildren(['latitude', 'longitude', 'lock', 'timestamp', 'deviceId'])"
        }
      }
    }
  }
}
```

## API Operations

### Reading Data

The app uses these methods to read from Firebase:

1. **Fetch all locks:** `FirebaseService.fetchLocks()` - reads from `/locks`
2. **Fetch single lock:** `FirebaseService.fetchLockById(lockId)` - reads from `/locks/{lockId}`
3. **Fetch all receivers:** `FirebaseService.fetchReceivers()` - reads from `/receivers`
4. **Fetch lock history:** `FirebaseService.fetchLockHistory(lockId)` - reads from `/history/{lockId}`
5. **Fetch all history:** `FirebaseService.fetchAllHistory()` - reads all `/history` data

### Writing Data

1. **Update lock status:** `FirebaseService.updateLockStatus(lockId, status)` - updates `/locks/{lockId}/lock` and `/locks/{lockId}/timestamp`

### Real-time Listeners

The app supports real-time data updates:

1. **Listen to single lock:** `FirebaseService.listenToLock(lockId)` - streams updates from `/locks/{lockId}`
2. **Listen to all locks:** `FirebaseService.listenToAllLocks()` - streams updates from `/locks`
3. **Listen to receivers:** `FirebaseService.listenToReceivers()` - streams updates from `/receivers`

## Testing Data

To test the app, populate your Firebase database with sample data. Use the Firebase Console or REST API:

### Sample REST API calls:

**Add a lock:**
```bash
curl -X PUT \
  https://gps-lock-application-default-rtdb.asia-southeast1.firebasedatabase.app/locks/LOCK_001.json \
  -H 'Content-Type: application/json' \
  -d '{
    "latitude": -6.2088,
    "longitude": 106.8456,
    "lock": "locked",
    "timestamp": "2025-10-20T14:30:00.000Z",
    "deviceId": "LOCK_001"
  }'
```

**Add a receiver:**
```bash
curl -X PUT \
  https://gps-lock-application-default-rtdb.asia-southeast1.firebasedatabase.app/receivers/RECEIVER_001.json \
  -H 'Content-Type: application/json' \
  -d '{
    "latitude": -6.218987,
    "longitude": 106.801851,
    "lock": "receiver",
    "timestamp": "2025-10-20T14:00:00.000Z",
    "deviceId": "RECEIVER_001"
  }'
```

**Add history entry:**
```bash
curl -X PUT \
  https://gps-lock-application-default-rtdb.asia-southeast1.firebasedatabase.app/history/LOCK_001/event_1729432800.json \
  -H 'Content-Type: application/json' \
  -d '{
    "latitude": -6.2088,
    "longitude": 106.8456,
    "lock": "unlocked",
    "timestamp": "2025-10-20T14:00:00.000Z",
    "deviceId": "LOCK_001"
  }'
```

## Migrating from Dummy Data

The app previously used dummy data which has been replaced with Firebase integration:

- ✅ **Removed:** `_useDummyData` flag in `MapRepositoryImpl`
- ✅ **Removed:** Dummy data fallbacks in repository methods
- ✅ **Removed:** Random data generation in `HistoryCubit`
- ✅ **Removed:** `MapDummyData` imports from cubits
- ✅ **Added:** `FirebaseService` for all database operations
- ✅ **Updated:** All repository methods to use Firebase
- ✅ **Updated:** History loading to fetch from Firebase

## Notes

- Device location (current user position) is still fetched from GPS, not Firebase
- Timestamps should be in ISO 8601 format
- Lock status values are case-sensitive: use "locked" or "unlocked"
- Image paths in history are optional and used for facial recognition captures
- The app queries history ordered by timestamp (newest first)
