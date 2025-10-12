import 'package:flutter/material.dart';
import '../../data/models/map_data.dart';

class LocationInfoPanel extends StatelessWidget {
  final MapData mapData;
  final Function(String) onUpdateLockStatus;

  const LocationInfoPanel({
    Key? key,
    required this.mapData,
    required this.onUpdateLockStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Live GPS Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Location info
            _buildInfoRow(
                "Lock Location:",
                "${mapData.lockLocation.latitude.toStringAsFixed(6)}, "
                    "${mapData.lockLocation.longitude.toStringAsFixed(6)}"),

            _buildInfoRow("Status:", mapData.lockLocation.lockStatus),

            _buildInfoRow(
                "Last Updated:", _formatTime(mapData.lockLocation.timestamp)),

            _buildInfoRow("Distance:", mapData.distanceInfo),

            // Device location if available
            if (mapData.deviceLocation != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                  "Your Location:",
                  "${mapData.deviceLocation!.latitude.toStringAsFixed(6)}, "
                      "${mapData.deviceLocation!.longitude.toStringAsFixed(6)}"),
            ],

            const SizedBox(height: 12),

            // Lock controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onUpdateLockStatus("locked"),
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text("Lock"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onUpdateLockStatus("unlocked"),
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text("Unlock"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Tracking status
            if (mapData.isTracking) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      "Next update in: ${mapData.countdown}s",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds}s ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else {
      return "${difference.inHours}h ago";
    }
  }
}
