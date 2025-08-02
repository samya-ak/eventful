import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class EnhancedImagePicker extends StatefulWidget {
  final Function(List<File> newImages, List<String> existingImages)
  onImagesChanged;
  final String? label;
  final double? height;
  final List<String>? existingImageUrls;
  final List<File>? initialNewImages;
  final bool allowMultiple;
  final int? maxImages;

  const EnhancedImagePicker({
    super.key,
    required this.onImagesChanged,
    this.label = 'Tap to upload image',
    this.height,
    this.existingImageUrls,
    this.initialNewImages,
    this.allowMultiple = false,
    this.maxImages = 5,
  });

  @override
  State<EnhancedImagePicker> createState() => _EnhancedImagePickerState();
}

class _EnhancedImagePickerState extends State<EnhancedImagePicker> {
  final ImagePicker _picker = ImagePicker();
  List<File> _newImages = [];
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    _newImages = widget.initialNewImages ?? [];
    _existingImages = widget.existingImageUrls ?? [];
  }

  @override
  void didUpdateWidget(EnhancedImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the state if the widget properties changed
    if (widget.existingImageUrls != oldWidget.existingImageUrls) {
      _existingImages = widget.existingImageUrls ?? [];
    }
    if (widget.initialNewImages != oldWidget.initialNewImages) {
      _newImages = widget.initialNewImages ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImages = _newImages.isNotEmpty || _existingImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: EdgeInsets.only(bottom: AppConstants.x2),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: AppColors.whiteWithAlpha(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        GestureDetector(
          onTap: hasImages
              ? null
              : _pickImage, // Only allow tap when no images (empty state)
          child: Container(
            width: double.infinity,
            height: widget.height ?? (hasImages ? 200 : 120),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppConstants.x2),
              border: Border.all(color: AppColors.whiteWithAlpha(0.3)),
            ),
            child: hasImages ? _buildImageDisplay() : _buildEmptyState(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 48,
          color: AppColors.whiteWithAlpha(0.5),
        ),
        SizedBox(height: AppConstants.x2),
        Text(
          widget.label ?? 'Tap to upload image',
          style: TextStyle(color: AppColors.whiteWithAlpha(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildImageDisplay() {
    if (widget.allowMultiple) {
      return _buildMultipleImagesView();
    } else {
      return _buildSingleImageView();
    }
  }

  Widget _buildSingleImageView() {
    Widget imageWidget;

    if (_newImages.isNotEmpty) {
      // Show new file image
      imageWidget = Image.file(
        _newImages.first,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_existingImages.isNotEmpty) {
      // Show existing network image
      imageWidget = Image.network(
        _existingImages.first,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.whiteWithAlpha(0.5),
              ),
              SizedBox(height: AppConstants.x2),
              Text(
                'Error loading image',
                style: TextStyle(
                  color: AppColors.whiteWithAlpha(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      );
    } else {
      return _buildEmptyState();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.x2),
      child: Stack(
        children: [
          imageWidget,
          // Remove button
          Positioned(
            top: AppConstants.x2,
            right: AppConstants.x2,
            child: GestureDetector(
              onTap: _removeCurrentImage,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImagesView() {
    final allImages = <Widget>[];

    // Add existing images
    for (int i = 0; i < _existingImages.length; i++) {
      allImages.add(
        _buildImageTile(
          isExisting: true,
          index: i,
          imageWidget: Image.network(
            _existingImages[i],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.error_outline,
                color: AppColors.whiteWithAlpha(0.5),
                size: 24,
              );
            },
          ),
        ),
      );
    }

    // Add new images
    for (int i = 0; i < _newImages.length; i++) {
      allImages.add(
        _buildImageTile(
          isExisting: false,
          index: i,
          imageWidget: Image.file(_newImages[i], fit: BoxFit.cover),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.x2),
      child: Stack(
        children: [
          GridView.count(
            padding: EdgeInsets.all(AppConstants.x2),
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            children: allImages,
          ),
          if (_canAddMoreImages())
            Positioned(
              bottom: AppConstants.x2,
              right: AppConstants.x2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppConstants.x4),
                ),
                child: IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTile({
    required bool isExisting,
    required int index,
    required Widget imageWidget,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.x1),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: imageWidget,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(isExisting, index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  bool _canAddMoreImages() {
    final totalImages = _newImages.length + _existingImages.length;
    return totalImages < (widget.maxImages ?? 5);
  }

  void _pickImage() async {
    try {
      if (widget.allowMultiple) {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          final List<File> newFiles = images
              .map((xFile) => File(xFile.path))
              .toList();
          final int totalImages = _newImages.length + _existingImages.length;
          final int availableSlots = (widget.maxImages ?? 5) - totalImages;
          final List<File> filesToAdd = newFiles.take(availableSlots).toList();

          setState(() {
            _newImages.addAll(filesToAdd);
          });
          _notifyChange();
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          final selectedFile = File(image.path);
          setState(() {
            // For single image, replace everything with the new image
            // Only clear existing images after successfully selecting new one
            _newImages = [selectedFile];
            _existingImages.clear();
          });
          _notifyChange();
        }
        // If image is null (user canceled), don't change anything
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeCurrentImage() {
    setState(() {
      _newImages.clear();
      _existingImages.clear();
    });
    _notifyChange();
  }

  void _removeImage(bool isExisting, int index) {
    setState(() {
      if (isExisting) {
        _existingImages.removeAt(index);
      } else {
        _newImages.removeAt(index);
      }
    });
    _notifyChange();
  }

  void _notifyChange() {
    widget.onImagesChanged(_newImages, _existingImages);
  }
}
