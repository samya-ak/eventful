import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BoxFit boxFit;

  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.boxFit = BoxFit.cover,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.height,
        color: AppColors.secondary,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: AppColors.white, size: 48),
              SizedBox(height: AppConstants.x2),
              Text(
                'No images available',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return Container(
        height: widget.height,
        child: Image.network(
          widget.imageUrls.first,
          height: widget.height,
          width: double.infinity,
          fit: widget.boxFit,
          errorBuilder: (context, error, stackTrace) => Container(
            height: widget.height,
            color: AppColors.secondary,
            child: const Center(
              child: Icon(Icons.broken_image, color: AppColors.white, size: 48),
            ),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: widget.height,
              color: AppColors.secondary,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.imageUrls[index],
                height: widget.height,
                width: double.infinity,
                fit: widget.boxFit,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: widget.height,
                  color: AppColors.secondary,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.white,
                      size: 48,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: widget.height,
                    color: AppColors.secondary,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Page indicators
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.x2,
                vertical: AppConstants.x1,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppConstants.x4),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Navigation arrows (only show if more than 1 image)
          if (widget.imageUrls.length > 1) ...[
            // Left arrow
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: _currentIndex > 0
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Right arrow
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex < widget.imageUrls.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: _currentIndex < widget.imageUrls.length - 1
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
