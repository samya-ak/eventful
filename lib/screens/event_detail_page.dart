import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class EventDetailPage extends StatefulWidget {
  final String eventName;
  final String? eventDescription;
  final String? eventImageUrl;

  const EventDetailPage({
    super.key,
    required this.eventName,
    this.eventDescription,
    this.eventImageUrl,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isImageLoading = true;

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
                      print('Back button pressed'); // Debug line
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
                  onPressed: () {
                    // TODO: Implement add location functionality
                    print('Add Location tapped');
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
                child: Column(
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
                          const Text(
                            'Locations',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Empty state - start by adding location (centered in remaining space)
                    Expanded(
                      child: Center(
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
                      ),
                    ),
                    // Map Button at bottom
                    Padding(
                      padding: EdgeInsets.all(AppConstants.x4),
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement map functionality
                          print('Map tapped');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.x4,
                            vertical: AppConstants.x3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.x6,
                            ),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.map,
                              size: 18,
                              color: AppColors.black,
                            ),
                            SizedBox(width: AppConstants.x2),
                            const Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
        ],
      ),
    );
  }
}
