import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/image_carousel.dart';

class LocationDetailDrawer extends StatefulWidget {
  final String locationName;
  final String? description;
  final List<String> imageUrls;
  final VoidCallback? onClose;

  const LocationDetailDrawer({
    super.key,
    required this.locationName,
    this.description,
    required this.imageUrls,
    this.onClose,
  });

  @override
  State<LocationDetailDrawer> createState() => _LocationDetailDrawerState();
}

class _LocationDetailDrawerState extends State<LocationDetailDrawer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0.0;
  bool _isExpanded = false;
  bool _isImageCover = true; // Toggle for image fit mode

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDrawer() async {
    await _animationController.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final deltaY = details.delta.dy;

    if (_isExpanded) {
      // When expanded, only allow dragging down to close
      if (deltaY > 0) {
        setState(() {
          _dragOffset += deltaY;
        });
      }
    } else {
      // When not expanded, allow dragging up to expand or down to close
      setState(() {
        _dragOffset += deltaY;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_isExpanded) {
      // When expanded, check if should close or stay expanded
      if (_dragOffset > screenHeight * 0.3 || velocity > 300) {
        _closeDrawer();
      } else if (_dragOffset > screenHeight * 0.15 || velocity > 150) {
        // Collapse to normal size
        setState(() {
          _isExpanded = false;
          _dragOffset = 0.0;
        });
      } else {
        // Stay expanded
        setState(() {
          _dragOffset = 0.0;
        });
      }
    } else {
      // When not expanded
      if (_dragOffset < -screenHeight * 0.1 || velocity < -300) {
        // Expand to full screen
        setState(() {
          _isExpanded = true;
          _dragOffset = 0.0;
        });
      } else if (_dragOffset > screenHeight * 0.2 || velocity > 300) {
        // Close
        _closeDrawer();
      } else {
        // Stay at normal size
        setState(() {
          _dragOffset = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final normalHeight = screenHeight * 0.8;
    final expandedHeight = screenHeight;

    final currentHeight = _isExpanded ? expandedHeight : normalHeight;
    final finalOffset = _dragOffset;

    return GestureDetector(
      onTap: () {}, // Prevent closing when tapping on drawer content
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              _slideAnimation.value * currentHeight + finalOffset,
            ),
            child: GestureDetector(
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: Container(
                height: currentHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: _isExpanded
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, _isExpanded ? 0 : -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status bar spacing when expanded
                    if (_isExpanded) SizedBox(height: statusBarHeight),

                    // Drag handle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.x4,
                        vertical: AppConstants.x1,
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.whiteWithAlpha(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Image carousel with overlay title and controls
                    Expanded(
                      flex: _isExpanded
                          ? 2
                          : 3, // 40% when expanded, 60% when normal
                      child: Stack(
                        children: [
                          // Image carousel
                          ImageCarousel(
                            imageUrls: widget.imageUrls,
                            height: double.infinity,
                            boxFit: _isImageCover
                                ? BoxFit.cover
                                : BoxFit.contain,
                          ),

                          // Image fit toggle button (top right)
                          if (widget.imageUrls.isNotEmpty)
                            Positioned(
                              top: AppConstants.x2,
                              right: AppConstants.x2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isImageCover = !_isImageCover;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    _isImageCover
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                          // Location name overlay with gradient background
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.x4,
                                vertical: AppConstants.x3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.4),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                              child: Text(
                                widget.locationName,
                                style: const TextStyle(
                                  color: AppColors.white,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Description section
                    Expanded(
                      flex: _isExpanded
                          ? 3
                          : 2, // 60% when expanded, 40% when normal
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.description != null &&
                                widget.description!.isNotEmpty) ...[
                              // Fixed header that stays visible when scrolling
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  AppConstants.x4,
                                  AppConstants.x4,
                                  AppConstants.x4,
                                  AppConstants.x2,
                                ),
                                child: const Text(
                                  'Description',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Scrollable content area
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppConstants.x4,
                                    0,
                                    AppConstants.x4,
                                    AppConstants.x4,
                                  ),
                                  child: Text(
                                    widget.description!,
                                    style: TextStyle(
                                      color: AppColors.whiteWithAlpha(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppConstants.x4,
                                    ),
                                    child: Text(
                                      'No description available',
                                      style: TextStyle(
                                        color: AppColors.whiteWithAlpha(0.6),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper function to show the drawer
void showLocationDetailDrawer(
  BuildContext context, {
  required String locationName,
  String? description,
  required List<String> imageUrls,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LocationDetailDrawer(
      locationName: locationName,
      description: description,
      imageUrls: imageUrls,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
