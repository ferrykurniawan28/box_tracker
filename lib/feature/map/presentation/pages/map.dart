// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lockguard/feature/map/data/models/map_data.dart';
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
  bool _showRouteInfo = true;
  LockInfo? _selectedLock;
  bool _showInfoPanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapCubit>().initializeMap();
    });
  }

  void _onLockTap(LockInfo lockInfo) {
    setState(() {
      _selectedLock = lockInfo;
      _showInfoPanel = true;
    });

    // Animate map to center on the selected lock
    final lockLatLng =
        LatLng(lockInfo.location.latitude, lockInfo.location.longitude);
    _mapController.move(lockLatLng, 15.0);
  }

  void _closeInfoPanel() {
    setState(() {
      _showInfoPanel = false;
      _selectedLock = null;
    });
  }

  Widget _buildMap(MapDataLoaded mapState) {
    final locks = mapState.mapData.locks;
    final receivers =
        mapState.mapData.receivers; // NEW: Get receivers from data
    final deviceLocation = mapState.mapData.deviceLocation;

    // Build markers
    final markers = <Marker>[];

    // Add markers for all locks
    for (final lockInfo in locks) {
      final lockLocation = lockInfo.location;
      final lockLatLng = LatLng(lockLocation.latitude, lockLocation.longitude);
      final isSelected =
          _selectedLock?.location.deviceId == lockLocation.deviceId;

      markers.add(
        Marker(
          point: lockLatLng,
          width: isSelected ? 140 : 120,
          height: isSelected ? 120 : 100,
          child: GestureDetector(
            onTap: () => _onLockTap(lockInfo),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated lock icon with status badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lockLocation.lockStatus == "locked"
                            ? Colors.green.withOpacity(0.9)
                            : Colors.red.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.yellow : Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isSelected ? 0.4 : 0.3),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        lockLocation.lockStatus == "locked"
                            ? Icons.lock
                            : Icons.lock_open,
                        color: Colors.white,
                        size: isSelected ? 28 : 24,
                      ),
                    ),
                    // Status indicator dot
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: lockLocation.lockStatus == "locked"
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Lock label with better styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.yellow.withOpacity(0.9)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
                        blurRadius: isSelected ? 6 : 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    lockLocation.deviceId ?? "LOCK",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black87 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add markers for all receivers
    for (final receiver in receivers) {
      markers.add(
        Marker(
          point: LatLng(receiver.latitude, receiver.longitude),
          width: 120,
          height: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.radar,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  receiver.deviceId ?? "RECEIVER",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add device location marker if available
    if (deviceLocation != null) {
      markers.add(
        Marker(
          point: LatLng(deviceLocation.latitude, deviceLocation.longitude),
          width: 120,
          height: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  deviceLocation.deviceId ?? "DEVICE",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

    // Build polylines - use routes from all locks
    List<Polyline> polylines = [];

    // Add routes for each lock with different colors
    for (int i = 0; i < locks.length; i++) {
      final lockInfo = locks[i];
      final isSelected =
          _selectedLock?.location.deviceId == lockInfo.location.deviceId;

      // Device to lock route
      if (lockInfo.deviceToLockRoute.isNotEmpty) {
        polylines.add(
          Polyline(
            points: lockInfo.deviceToLockRoute,
            strokeWidth: isSelected ? 8.0 : 6.0,
            color: Colors.orange.withOpacity(isSelected ? 0.9 : 0.8),
            borderStrokeWidth: isSelected ? 3.0 : 2.0,
            borderColor: Colors.white.withOpacity(0.8),
          ),
        );
      }

      // Receiver to lock routes (from multiple receivers)
      final receiverRoutes = lockInfo.receiverToLockRoutes;
      if (receiverRoutes.isNotEmpty) {
        // Use different colors for different receivers
        final receiverColors = [
          Colors.blue,
          Colors.green,
          Colors.purple,
          Colors.teal,
          Colors.indigo,
        ];

        int colorIndex = 0;
        for (final entry in receiverRoutes.entries) {
          final route = entry.value;

          if (route.isNotEmpty) {
            final color = receiverColors[colorIndex % receiverColors.length];
            polylines.add(
              Polyline(
                points: route,
                strokeWidth: isSelected ? 7.0 : 5.0,
                color: color.withOpacity(isSelected ? 0.8 : 0.7),
                borderStrokeWidth: isSelected ? 2.5 : 1.5,
                borderColor: Colors.white.withOpacity(0.8),
              ),
            );
            colorIndex++;
          }
        }
      }
    }

    // Fallback to simple polylines if no routes available
    if (polylines.isEmpty && locks.isNotEmpty && receivers.isNotEmpty) {
      // Create direct lines from each receiver to each lock
      final receiverColors = [
        Colors.red,
        Colors.orange,
        Colors.pink,
        Colors.brown
      ];

      for (int receiverIndex = 0;
          receiverIndex < receivers.length;
          receiverIndex++) {
        final receiver = receivers[receiverIndex];
        final receiverLatLng = LatLng(receiver.latitude, receiver.longitude);
        final color = receiverColors[receiverIndex % receiverColors.length];

        for (final lockInfo in locks) {
          final lockLatLng =
              LatLng(lockInfo.location.latitude, lockInfo.location.longitude);
          final polylinePoints = [receiverLatLng, lockLatLng];
          polylines.add(
            Polyline(
              points: polylinePoints,
              strokeWidth: 4.0,
              color: color.withOpacity(0.5),
              strokeCap: StrokeCap.round,
            ),
          );
        }
      }
    }

    return Stack(
      children: [
        // Gray background for when tiles fail to load
        Container(
          color: Colors.grey[200],
        ),

        // Enhanced Map with better tile layer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: receivers.isNotEmpty
                ? LatLng(receivers.first.latitude, receivers.first.longitude)
                : const LatLng(-6.218987, 106.801851), // Fallback to Jakarta
            initialZoom: 15.0,
            onTap: (_, __) {
              // Close info panel when tapping on empty map area
              if (_showInfoPanel) {
                _closeInfoPanel();
              }
            },
            onMapReady: () {
              // Center map on first receiver location when ready
              if (receivers.isNotEmpty) {
                final firstReceiver = receivers.first;
                _mapController.move(
                    LatLng(firstReceiver.latitude, firstReceiver.longitude),
                    15.0);
              }
            },
          ),
          children: [
            // Enhanced map tiles with error handling for offline use
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.lockguard.app',
              maxNativeZoom: 19,
              maxZoom: 19,
              // Tiles will fail gracefully if offline - map will still show markers and routes
              tileProvider: NetworkTileProvider(),
            ),

            // Polylines (routes)
            PolylineLayer(polylines: polylines),

            // Markers
            MarkerLayer(markers: markers),
          ],
        ),

        // Enhanced Controls overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Route info toggle
                _buildRouteInfoToggle(),
                const SizedBox(height: 8),
                // Map controls
                MapControls(
                  isTracking: mapState.mapData.isTracking,
                  onToggleTracking: () {
                    context.read<MapCubit>().toggleTracking();
                  },
                  onCenterMap: () {
                    if (locks.isNotEmpty) {
                      final firstLock = locks.first;
                      final lockLatLng = LatLng(firstLock.location.latitude,
                          firstLock.location.longitude);
                      _mapController.move(lockLatLng, 15.0);
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Route Legend
        if (_showRouteInfo && polylines.isNotEmpty) ...[
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildRouteLegend(),
          ),
        ],

        // Info panel overlay - Only shown when a lock is selected
        if (_showInfoPanel && _selectedLock != null) ...[
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildLockInfoPanel(_selectedLock!, mapState),
          ),
        ],

        // Close button for info panel
        if (_showInfoPanel && _selectedLock != null) ...[
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildCloseButton(),
          ),
        ],

        // Routes loading indicator
        if (mapState.mapData.isLoadingRoutes) ...[
          Positioned(
            bottom: 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading routes...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLockInfoPanel(LockInfo lockInfo, MapDataLoaded mapState) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: LocationInfoPanel(
        key: ValueKey(lockInfo.location.deviceId),
        mapData: mapState.mapData,
        selectedLock: lockInfo,
        onUpdateLockStatus: (status) {
          final lockId = lockInfo.location.deviceId ?? "LOCK_001";
          context.read<MapCubit>().updateLockStatus(lockId, status);
        },
        onClose: _closeInfoPanel,
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: _closeInfoPanel,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRouteInfoToggle() {
    return Tooltip(
      message: _showRouteInfo ? 'Hide route info' : 'Show route info',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showRouteInfo = !_showRouteInfo;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _showRouteInfo ? Colors.blue.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.route,
            size: 20,
            color: _showRouteInfo ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteLegend() {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        if (state is! MapDataLoaded) return const SizedBox.shrink();

        final routesCount = state.mapData.locks.fold<int>(0, (count, lock) {
          final deviceRoutes = lock.deviceToLockRoute.isNotEmpty ? 1 : 0;
          final receiverRoutes = lock.receiverToLockRoutes.length;
          return count + deviceRoutes + receiverRoutes;
        });

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Routes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: state.mapData.isLoadingRoutes
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.mapData.isLoadingRoutes
                          ? 'Loading...'
                          : '$routesCount loaded',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: state.mapData.isLoadingRoutes
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLegendItem('Device to Lock', Colors.orange),
              const SizedBox(height: 4),
              _buildLegendItem('Receiver 1 to Lock', Colors.blue),
              const SizedBox(height: 4),
              _buildLegendItem('Receiver 2 to Lock', Colors.green),
              const SizedBox(height: 4),
              _buildLegendItem('Receiver 3+ to Lock', Colors.purple),
              const SizedBox(height: 4),
              _buildLegendItem('Direct Line', Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text(
          "LockGuard Map",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Refresh button with better styling
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: () {
              context.read<MapCubit>().fetchLockLocation();
              context.read<MapCubit>().fetchDeviceLocation();
            },
          ),
        ],
      ),
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, mapState) {
          if (mapState is MapInitial || mapState is MapLoading) {
            return _buildLoadingState();
          }

          if (mapState is MapError) {
            return _buildErrorState(mapState);
          }

          if (mapState is MapDataLoaded) {
            return _buildMap(mapState);
          }

          return _buildUnknownState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                Icon(
                  Icons.map_rounded,
                  color: Colors.blue,
                  size: 30,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Map Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting lock locations and routes...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(MapError errorState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorState.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MapCubit>().initializeMap();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Unknown State',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
