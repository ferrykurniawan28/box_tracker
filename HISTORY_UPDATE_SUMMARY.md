# History Page Update Summary

## Overview

Updated the history page to display success and failed images based on authorized/unauthorized unlock attempts. **Important**: Unauthorized attempts are shown as "locked" (failed to unlock) to indicate that the lock remained secure and blocked the intruder.

## Changes Made

### 1. **Updated `HistoryEntry` Model**

- **File**: `lib/feature/map/presentation/cubit/history/history_state.dart`
- **Changes**:
  - Added `isAuthorized` field (bool) - Indicates if the unlock attempt was authorized
  - Added `imagePath` field (String?) - Path to the success or failed image
  - Updated `toMap()` method to include the new fields

### 2. **Updated `HistoryCubit`**

- **File**: `lib/feature/map/presentation/cubit/history/history_cubit.dart`
- **Changes**:
  - Added `dart:math` import for random number generation
  - Modified `fetchLiveTrackingData()` to randomly simulate three scenarios:
    - **Scenario 1 (33%)**: Authorized unlock - Display as "unlocked" with success image
    - **Scenario 2 (33%)**: Unauthorized unlock attempt - Display as "locked" with intruder image (alert!)
    - **Scenario 3 (33%)**: No attempt - Keep current lock status, no image

### 3. **Updated History Page UI**

- **File**: `lib/feature/map/presentation/pages/history.dart`
- **Changes**:
  - Updated lock status display logic:
    - **Locked (no image)**: Green - Normal locked state
    - **Locked (with image)**: Red - Unauthorized attempt blocked
    - **Unlocked**: Blue - Authorized access granted
  - Display images for both scenarios:
    - Success images when authorized unlock occurs
    - Intruder images when unauthorized attempt is blocked
  - Show appropriate messages:
    - Success: "Success: Authorized access granted" (blue)
    - Warning: "Alert: Unauthorized access detected - Intruder!" (red)

### 4. **Updated Dummy Data**

- **File**: `lib/feature/map/data/datasource/dummy.dart`
- **Changes**:
  - Added `getRandomUnlockImage()` helper method
  - Method returns random image path based on authorization status

## Image Assets Used

- **Success Images** (authorized unlock):

  - `assets/images/sucess-1.jpeg`
  - `assets/images/sucess-2.jpeg`
  - `assets/images/sucess-3.jpeg`
  - `assets/images/sucess-4.jpeg`

- **Failed Images** (unauthorized unlock - intruder):
  - `assets/images/failed-1.jpeg`
  - `assets/images/failed-2.jpeg`
  - `assets/images/failed-3.jpeg`
  - `assets/images/failed-4.jpeg`

## How It Works

1. **Locked Status (Normal)**:

   - No image displayed
   - Green color
   - No warning message
   - Text: "Lock Status: locked"

2. **Authorized Unlock**:

   - **Lock status shows as "unlocked"**
   - Random success image displayed (sucess-1 to sucess-4)
   - Blue color scheme
   - Success message: "Success: Authorized access granted"
   - Text: "Lock Status: unlocked (Authorized)"

3. **Unauthorized Attempt** (Intruder Blocked):
   - **Lock status shows as "locked" (because the lock remained secure and didn't unlock)**
   - Random failed/intruder image displayed (failed-1 to failed-4)
   - Red color scheme
   - Warning message: "Alert: Unauthorized access detected - Intruder!"
   - Text: "Lock Status: Locked (Unauthorized Attempt Blocked)"

## Logic Flow

The system randomly simulates three scenarios (each with ~33% probability):

- **Scenario 1 (33%)**: Authorized unlock attempt → Lock opens → Status: "unlocked" + Success image
- **Scenario 2 (33%)**: Unauthorized unlock attempt → Lock stays locked → Status: "locked" + Intruder image + Alert
- **Scenario 3 (33%)**: No unlock attempt → Keep current status → No image

This makes sense because:

- ✅ Authorized users successfully unlock the lock
- ❌ Unauthorized users (intruders) FAIL to unlock, so the lock remains "locked" and captures their image
- 🔒 Sometimes no one tries to unlock, so the lock just stays in its current state

## Testing

To test the functionality:

1. Navigate to the History page
2. Start auto-update
3. Observe the history entries as they are created
4. Each update will randomly show one of three scenarios:
   - **Unlocked (Blue)**: Authorized access with success image
   - **Locked (Red)**: Unauthorized attempt blocked with intruder image + Alert
   - **Locked (Green)**: Normal status, no unlock attempt

## Future Enhancements

Consider implementing:

- Real-time authorization checking from Firebase/backend
- Face recognition integration
- Push notifications for unauthorized access
- Ability to report/dismiss false positives
