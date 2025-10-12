import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final VoidCallback onCenterMap;

  const MapControls({
    Key? key,
    required this.isTracking,
    required this.onToggleTracking,
    required this.onCenterMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Center map button
        FloatingActionButton(
          onPressed: onCenterMap,
          mini: true,
          backgroundColor: Colors.white,
          child: const Icon(Icons.center_focus_strong, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        // Tracking toggle button
        FloatingActionButton(
          onPressed: onToggleTracking,
          backgroundColor: isTracking ? Colors.red : Colors.blue,
          child: Icon(
            isTracking ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
