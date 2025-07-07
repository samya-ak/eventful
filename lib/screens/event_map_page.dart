import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class EventMapPage extends StatefulWidget {
  final String eventName;
  final List<Map<String, dynamic>> locations;

  const EventMapPage({
    super.key,
    required this.eventName,
    required this.locations,
  });

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  final MapController _mapController = MapController();
  late LatLng _initialCenter;
  late double _initialZoom;

  @override
  void initState() {
    super.initState();
    _calculateInitialView();
  }

  void _calculateInitialView() {
    if (widget.locations.isEmpty) {
      // Default to Kathmandu, Nepal if no locations
      _initialCenter = const LatLng(27.7172, 85.3240);
      _initialZoom = 15.0;
      return;
    }

    // Get all coordinates
    List<LatLng> coordinates = [];
    for (var location in widget.locations) {
      final latitude = location['latitude'];
      final longitude = location['longitude'];
      if (latitude != null && longitude != null) {
        coordinates.add(LatLng(latitude.toDouble(), longitude.toDouble()));
      }
    }

    if (coordinates.isEmpty) {
      // Default to Kathmandu, Nepal if no valid coordinates
      _initialCenter = const LatLng(27.7172, 85.3240);
      _initialZoom = 15.0;
      return;
    }

    if (coordinates.length == 1) {
      // If only one location, center on it
      _initialCenter = coordinates.first;
      _initialZoom = 15.0;
      return;
    }

    // Calculate bounding box for multiple locations
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (var coord in coordinates) {
      minLat = minLat > coord.latitude ? coord.latitude : minLat;
      maxLat = maxLat < coord.latitude ? coord.latitude : maxLat;
      minLng = minLng > coord.longitude ? coord.longitude : minLng;
      maxLng = maxLng < coord.longitude ? coord.longitude : maxLng;
    }

    // Calculate center
    _initialCenter = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Calculate zoom level based on the span
    double latSpan = maxLat - minLat;
    double lngSpan = maxLng - minLng;
    double maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    // Determine zoom level (approximate calculation)
    if (maxSpan > 10) {
      _initialZoom = 5.0;
    } else if (maxSpan > 5) {
      _initialZoom = 7.0;
    } else if (maxSpan > 1) {
      _initialZoom = 10.0;
    } else if (maxSpan > 0.1) {
      _initialZoom = 12.0;
    } else if (maxSpan > 0.01) {
      _initialZoom = 14.0;
    } else {
      _initialZoom = 15.0;
    }

    print(
      'DEBUG: Calculated initial center: $_initialCenter, zoom: $_initialZoom',
    );
    print('DEBUG: Locations count: ${coordinates.length}');
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    for (var location in widget.locations) {
      final latitude = location['latitude'];
      final longitude = location['longitude'];
      final locationName = location['location_name'] ?? 'Unnamed Location';

      if (latitude != null && longitude != null) {
        markers.add(
          Marker(
            point: LatLng(latitude.toDouble(), longitude.toDouble()),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Show location name when marker is tapped
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locationName),
                    backgroundColor: AppColors.secondary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 1.0,
              maxZoom: 22.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mattya',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Back button with gradient overlay at top
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 100 + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(120),
                    Colors.black.withAlpha(80),
                    Colors.black.withAlpha(40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Back button and title
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    splashRadius: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.x2),
                Expanded(
                  child: Text(
                    widget.eventName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        zoom + 1,
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.black,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        zoom - 1,
                      );
                    },
                    icon: const Icon(
                      Icons.remove,
                      color: AppColors.black,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Location count info at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.x3,
                vertical: AppConstants.x2,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppConstants.x2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.white,
                    size: 16,
                  ),
                  const SizedBox(width: AppConstants.x1),
                  Text(
                    '${widget.locations.length} location${widget.locations.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
