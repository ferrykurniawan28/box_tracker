import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lockguard/feature/map/presentation/widgets/location_info.dart';
import 'package:lockguard/feature/map/presentation/widgets/map_controls.dart';
import '../cubit/map/map_cubit.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapCubit>().initializeMap();
    });
  }

  Widget _buildMap(MapDataLoaded mapState) {
    final lockLocation = mapState.mapData.lockLocation;
    final deviceLocation = mapState.mapData.deviceLocation;

    final lockLatLng = LatLng(lockLocation.latitude, lockLocation.longitude);
    final receiverLatLng = const LatLng(-6.218987, 106.801851);

    // Build markers
    final markers = <Marker>[
      // Lock location marker with device ID label
      Marker(
        point: lockLatLng,
        width: 100,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              lockLocation.lockStatus == "locked"
                  ? Icons.lock
                  : Icons.lock_open,
              color: lockLocation.lockStatus == "locked"
                  ? Colors.green
                  : Colors.red,
              size: 35,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey, width: 0.5),
              ),
              child: Text(
                lockLocation.deviceId ?? "LOCK",
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      // Receiver location marker
      Marker(
        point: receiverLatLng,
        width: 100,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 35,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey, width: 0.5),
              ),
              child: const Text(
                "RECEIVER",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];

    // Add device location marker if available
    if (deviceLocation != null) {
      markers.add(
        Marker(
          point: LatLng(deviceLocation.latitude, deviceLocation.longitude),
          width: 100,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_android,
                color: Colors.orange,
                size: 35,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey, width: 0.5),
                ),
                child: Text(
                  deviceLocation.deviceId ?? "DEVICE",
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build polylines - use routes from MapData
    List<Polyline> polylines = [];

    // Add device to lock route if available
    if (mapState.mapData.deviceToLockRoute.isNotEmpty) {
      polylines.add(
        Polyline(
          points: mapState.mapData.deviceToLockRoute,
          strokeWidth: 5.0,
          color: Colors.red,
        ),
      );
    }

    // Add receiver to lock route if available
    if (mapState.mapData.receiverToLockRoute.isNotEmpty) {
      polylines.add(
        Polyline(
          points: mapState.mapData.receiverToLockRoute,
          strokeWidth: 5.0,
          color: Colors.blue,
          pattern: StrokePattern.dashed(segments: [8, 5]),
        ),
      );
    }

    // Fallback to simple polylines if no routes available
    if (polylines.isEmpty) {
      final polylinePoints = [receiverLatLng, lockLatLng];
      polylines.add(
        Polyline(
          points: polylinePoints,
          strokeWidth: 4.0,
          color: Colors.red.withOpacity(0.7),
        ),
      );
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: receiverLatLng,
            initialZoom: 15.0,
            onMapReady: () {
              // Center map on lock location when ready
              _mapController.move(lockLatLng, 15.0);
            },
          ),
          children: [
            // Map tiles
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.lockguard',
            ),
            // Polylines (routes)
            PolylineLayer(polylines: polylines),
            // Markers
            MarkerLayer(markers: markers),
          ],
        ),

        // Controls overlay
        Positioned(
          top: 16,
          right: 16,
          child: MapControls(
            isTracking: mapState.mapData.isTracking,
            onToggleTracking: () {
              context.read<MapCubit>().toggleTracking();
            },
            onCenterMap: () {
              final lockLocation = mapState.mapData.lockLocation;
              final lockLatLng =
                  LatLng(lockLocation.latitude, lockLocation.longitude);
              _mapController.move(lockLatLng, 15.0);
            },
          ),
        ),

        // Info panel overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: LocationInfoPanel(
            mapData: mapState.mapData,
            onUpdateLockStatus: (status) {
              context.read<MapCubit>().updateLockStatus(status);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Live GPS Map",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<MapCubit>().fetchLockLocation();
              context.read<MapCubit>().fetchDeviceLocation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.directions, color: Colors.white),
            onPressed: () {
              // Routes are automatically calculated when locations are fetched
              context.read<MapCubit>().fetchLockLocation();
              context.read<MapCubit>().fetchDeviceLocation();
            },
          ),
        ],
      ),
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, mapState) {
          if (mapState is MapInitial || mapState is MapLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map data...'),
                ],
              ),
            );
          }

          if (mapState is MapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${mapState.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MapCubit>().initializeMap();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (mapState is MapDataLoaded) {
            return _buildMap(mapState);
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
