import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/kml_parser.dart';
import '../widgets/location_detail_drawer.dart';

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
  KmlData? _kmlData;
  bool _isLoadingKml = false;

  @override
  void initState() {
    super.initState();
    _loadKmlDataIfNeeded();
    _calculateInitialView();
  }

  Future<void> _loadKmlDataIfNeeded() async {
    setState(() {
      _isLoadingKml = true;
    });

    try {
      // Use Flutter's asset loading instead of File system
      const kmlPath = 'lib/routes/mattya-2082.kml';
      final kmlData = await KmlParser.parseKmlAsset(kmlPath);

      if (mounted) {
        setState(() {
          _kmlData = kmlData;
          _isLoadingKml = false;
        });

        // Recalculate initial view to include KML data
        _calculateInitialView();
      }
    } catch (e) {
      print('Error loading KML data: $e');
      if (mounted) {
        setState(() {
          _isLoadingKml = false;
        });
      }
    }
  }

  void _calculateInitialView() {
    List<LatLng> allCoordinates = [];

    // Add regular locations
    for (var location in widget.locations) {
      final latitude = location['latitude'];
      final longitude = location['longitude'];
      if (latitude != null && longitude != null) {
        allCoordinates.add(LatLng(latitude.toDouble(), longitude.toDouble()));
      }
    }

    // Add KML data if available (only polyline coordinates, not placemarks)
    if (_kmlData != null) {
      // Add KML polyline coordinates only
      for (var polyline in _kmlData!.polylines) {
        allCoordinates.addAll(polyline.coordinates);
      }
    }
    if (allCoordinates.isEmpty) {
      // Default to Kathmandu, Nepal if no coordinates
      _initialCenter = const LatLng(27.7172, 85.3240);
      _initialZoom = 15.0;
      return;
    }

    if (allCoordinates.length == 1) {
      // If only one location, center on it
      _initialCenter = allCoordinates.first;
      _initialZoom = 15.0;
      return;
    }

    // Calculate bounding box for all coordinates
    double minLat = allCoordinates.first.latitude;
    double maxLat = allCoordinates.first.latitude;
    double minLng = allCoordinates.first.longitude;
    double maxLng = allCoordinates.first.longitude;

    for (var coord in allCoordinates) {
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
    print('DEBUG: Total coordinates count: ${allCoordinates.length}');
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Add regular location markers
    for (var location in widget.locations) {
      final latitude = location['latitude'];
      final longitude = location['longitude'];
      final locationName = location['location_name'] ?? 'Unnamed Location';
      final locationDescription = location['location_description'];
      final List<String> imageUrls =
          (location['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      if (latitude != null && longitude != null) {
        markers.add(
          Marker(
            point: LatLng(latitude.toDouble(), longitude.toDouble()),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Show location detail drawer when marker is tapped
                showLocationDetailDrawer(
                  context,
                  locationName: locationName,
                  description: locationDescription,
                  imageUrls: imageUrls,
                );
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }
    }

    // Note: KML placemark markers are intentionally not added - only showing polylines
    // If you want to add KML placemarks back, uncomment the code below:
    /*
    // Add KML placemark markers
    if (_kmlData != null) {
      for (var placemark in _kmlData!.placemarks) {
        markers.add(
          Marker(
            point: placemark.coordinates,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Show KML placemark detail drawer when marker is tapped
                showLocationDetailDrawer(
                  context,
                  locationName: placemark.name,
                  description: placemark.description,
                  imageUrls: <String>[], // KML placemarks don't have images
                );
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ),
        );
      }
    }
    */

    return markers;
  }

  List<Polyline> _buildPolylines() {
    List<Polyline> polylines = [];

    if (_kmlData != null) {
      for (var kmlPolyline in _kmlData!.polylines) {
        polylines.add(
          Polyline(
            points: kmlPolyline.coordinates,
            strokeWidth: 4.0,
            color: Colors.purple,
          ),
        );
      }
    }

    return polylines;
  }

  String _buildLocationCountText() {
    int totalLocations = widget.locations.length;
    int kmlRoutes = _kmlData?.polylines.length ?? 0;

    String text = '';

    if (totalLocations > 0) {
      text += '$totalLocations location${totalLocations != 1 ? 's' : ''}';
    }

    if (kmlRoutes > 0) {
      if (text.isNotEmpty) text += ' • ';
      text += '$kmlRoutes route${kmlRoutes != 1 ? 's' : ''}';
    }

    return text.isEmpty ? 'No locations' : text;
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
              if (_kmlData != null && _kmlData!.polylines.isNotEmpty)
                PolylineLayer(polylines: _buildPolylines()),
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

          // KML Loading overlay
          if (_isLoadingKml)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 60,
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
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: AppConstants.x2),
                    const Text(
                      'Loading route data...',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                    _buildLocationCountText(),
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
