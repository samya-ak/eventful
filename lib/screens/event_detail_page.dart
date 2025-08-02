import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/supabase_service.dart';
import '../widgets/three_dot_menu.dart';
import '../models/location.dart';
import 'add_location_page.dart';
import 'edit_location_page.dart';
import 'event_map_page.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String? eventDescription;
  final String? eventImageUrl;

  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.eventDescription,
    this.eventImageUrl,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isImageLoading = true;
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      setState(() {
        _isLoadingLocations = true;
      });

      final locations = await SupabaseService.getLocationsForEvent(
        widget.eventId,
      );

      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('Error fetching locations: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
  }

  Future<void> _handleEditLocation(Map<String, dynamic> location) async {
    // Create a Location object from the map data
    final locationData = Location(
      locationId: location['location_id'],
      eventId: widget.eventId,
      locationName: location['location_name'] ?? '',
      description: location['location_description'],
      latitude: location['latitude']?.toDouble() ?? 0.0,
      longitude: location['longitude']?.toDouble() ?? 0.0,
      images: (location['images'] as List<dynamic>?)?.cast<String>(),
      createdAt: location['created_at'] != null
          ? DateTime.parse(location['created_at'])
          : null,
      updatedAt: location['updated_at'] != null
          ? DateTime.parse(location['updated_at'])
          : null,
    );

    // Navigate to edit location page
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EditLocationPage(eventId: widget.eventId, location: locationData),
      ),
    );

    // Refresh locations if edit was successful
    if (result == true) {
      _fetchLocations();
    }
  }

  Future<void> _handleDeleteLocation(
    String locationId,
    String locationName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          title: const Text(
            'Delete Location',
            style: TextStyle(color: AppColors.white),
          ),
          content: Text(
            'Are you sure you want to delete "$locationName"? This action cannot be undone.',
            style: TextStyle(color: AppColors.whiteWithAlpha(0.9)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteLocation(locationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location "$locationName" deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the locations list
          _fetchLocations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete location: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final String locationName = location['location_name'] ?? 'Unnamed Location';
    final String? locationDescription = location['location_description'];
    final String locationId = location['location_id'];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.x4,
        vertical: AppConstants.x1,
      ),
      padding: const EdgeInsets.all(AppConstants.x3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.x2),
        border: Border.all(color: AppColors.whiteWithAlpha(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Location icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppConstants.x1),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.x3),
          // Location info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (locationDescription != null &&
                    locationDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.x1),
                    child: Text(
                      locationDescription,
                      style: TextStyle(
                        color: AppColors.whiteWithAlpha(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Three-dot menu
          ThreeDotMenu(
            onEdit: () => _handleEditLocation(location),
            onDelete: () => _handleDeleteLocation(locationId, locationName),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double imageHeight =
        MediaQuery.of(context).size.height / 3 +
        MediaQuery.of(context).padding.top;
    const String fallbackImage =
        'https://via.placeholder.com/600x300.png?text=No+Image';
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // Event Image with overlayed text
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: imageHeight,
                child: Stack(
                  children: [
                    Image.network(
                      (widget.eventImageUrl != null &&
                              widget.eventImageUrl!.isNotEmpty)
                          ? widget.eventImageUrl!
                          : fallbackImage,
                      width: double.infinity,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          // Image has loaded successfully
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _isImageLoading) {
                              setState(() {
                                _isImageLoading = false;
                              });
                            }
                          });
                          return child;
                        }
                        // Image is still loading
                        return Container(
                          color: AppColors.secondary,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: AppColors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.secondary,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Back button with gradient overlay at top
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 40 + MediaQuery.of(context).padding.top,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(120),
                        Colors.black.withAlpha(60),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7],
                    ),
                  ),
                ),
              ),
              // Back button positioned separately
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: Material(
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
              ),
              // Event title and description at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.x4,
                    vertical: AppConstants.x4,
                  ),
                  decoration: BoxDecoration(
                    // Use a vertical gradient for text visibility
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(100),
                        Colors.black.withAlpha(180),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 30), // Add bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (widget.eventDescription != null &&
                            widget.eventDescription!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              widget.eventDescription!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppConstants.x4,
                bottom: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddLocationPage(eventId: widget.eventId),
                      ),
                    );
                    // Refresh locations list when returning from add location page
                    if (result == true || mounted) {
                      _fetchLocations();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.x3,
                      vertical: AppConstants.x2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.x4),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_location,
                        size: 16,
                        color: AppColors.black,
                      ),
                      SizedBox(width: AppConstants.x1),
                      const Text(
                        'Add Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Locations Card that overlaps the image and covers remaining area
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: AppColors.whiteWithAlpha(0.1),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(AppConstants.x4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.white,
                                size: 20,
                              ),
                              SizedBox(width: AppConstants.x2),
                              Text(
                                _isLoadingLocations
                                    ? 'Locations'
                                    : 'Locations${_locations.isNotEmpty ? ' (${_locations.length})' : ''}',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Empty state or locations list
                        Expanded(
                          child: _isLoadingLocations
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                  ),
                                )
                              : _locations.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_location_alt_outlined,
                                        color: AppColors.whiteWithAlpha(0.6),
                                        size: 32,
                                      ),
                                      SizedBox(height: AppConstants.x2),
                                      Text(
                                        'Start by adding location',
                                        style: TextStyle(
                                          color: AppColors.whiteWithAlpha(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchLocations,
                                  color: AppColors.button,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(
                                      top: AppConstants.x2,
                                      bottom:
                                          80, // Space for floating map button
                                    ),
                                    itemCount: _locations.length,
                                    itemBuilder: (context, index) {
                                      final location = _locations[index];
                                      return _buildLocationCard(location);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                    // Floating Map Button
                    if (_locations.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: AppConstants.x4,
                        child: Center(
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EventMapPage(
                                    eventName: widget.eventName,
                                    locations: _locations,
                                  ),
                                ),
                              );
                            },
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.black,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.x8,
                              ),
                            ),
                            icon: const Icon(
                              Icons.map,
                              size: 18,
                              color: AppColors.black,
                            ),
                            label: const Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
