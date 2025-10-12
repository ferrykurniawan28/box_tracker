import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/map_data.dart';

class LocationInfoPanel extends StatelessWidget {
  final MapData mapData;
  final LockInfo? selectedLock;
  final Function(String) onUpdateLockStatus;
  final VoidCallback? onClose;

  const LocationInfoPanel({
    Key? key,
    required this.mapData,
    this.selectedLock,
    required this.onUpdateLockStatus,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use selected lock if available, otherwise fall back to first lock
    final lockInfo =
        selectedLock ?? (mapData.locks.isNotEmpty ? mapData.locks.first : null);

    if (lockInfo == null) {
      return _buildNoLocksAvailable();
    }

    final lockLocation = lockInfo.location;

    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with lock name and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lockLocation.deviceId ?? "Lock Device",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _buildStatusChip(lockLocation.lockStatus),
                    ],
                  ),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onClose,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Location Information Section
            _buildSectionHeader("Location Information"),
            const SizedBox(height: 8),

            _buildInfoRow(
              "Coordinates:",
              "${lockLocation.latitude.toStringAsFixed(6)}, ${lockLocation.longitude.toStringAsFixed(6)}",
            ),
            _buildInfoRow(
              "Last Updated:",
              _formatTime(lockLocation.timestamp),
            ),

            // Route Information Section
            if (lockInfo.deviceToLockRoute.isNotEmpty ||
                lockInfo.receiverToLockRoute.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Route Information"),
              const SizedBox(height: 8),
              if (lockInfo.deviceToLockRoute.isNotEmpty) ...[
                _buildRouteInfo(
                  "Device to Lock",
                  _calculateRouteDistance(lockInfo.deviceToLockRoute),
                  Colors.orange,
                ),
              ],
              if (lockInfo.receiverToLockRoute.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildRouteInfo(
                  "Receiver to Lock",
                  _calculateRouteDistance(lockInfo.receiverToLockRoute),
                  Colors.blue,
                ),
              ],
            ],

            // Device Location (if available)
            if (mapData.deviceLocation != null) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Your Location"),
              const SizedBox(height: 8),
              _buildInfoRow(
                "Coordinates:",
                "${mapData.deviceLocation!.latitude.toStringAsFixed(6)}, ${mapData.deviceLocation!.longitude.toStringAsFixed(6)}",
              ),
            ],

            const SizedBox(height: 16),

            // Lock Controls
            _buildSectionHeader("Lock Controls"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    "Lock",
                    Icons.lock,
                    Colors.green,
                    lockLocation.lockStatus == "locked",
                    () => onUpdateLockStatus("locked"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildControlButton(
                    "Unlock",
                    Icons.lock_open,
                    Colors.red,
                    lockLocation.lockStatus == "unlocked",
                    () => onUpdateLockStatus("unlocked"),
                  ),
                ),
              ],
            ),

            // Tracking Status
            if (mapData.isTracking) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Live Tracking Active",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            "Next update in: ${mapData.countdown}s",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocksAvailable() {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "No Locks Available",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add locks to see their information here",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isLocked = status == "locked";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock : Icons.lock_open,
            size: 12,
            color: isLocked ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? "Locked" : "Unlocked",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isLocked ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(String label, String distance, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          distance,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    String text,
    IconData icon,
    Color color,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: isActive ? color : Colors.white,
      ),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? color : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color.withOpacity(0.2) : color,
        foregroundColor: isActive ? color : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive ? color : Colors.transparent,
            width: isActive ? 2 : 0,
          ),
        ),
        elevation: isActive ? 0 : 2,
      ),
    );
  }

  String _calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return "0 m";

    double totalDistance = 0;
    for (int i = 1; i < route.length; i++) {
      final prev = route[i - 1];
      final curr = route[i];
      final distance = _calculateDistance(
          prev.latitude, prev.longitude, curr.latitude, curr.longitude);
      totalDistance += distance;
    }

    if (totalDistance < 1000) {
      return "${totalDistance.round()} m";
    } else {
      return "${(totalDistance / 1000).toStringAsFixed(1)} km";
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds}s ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";
    }
  }
}
