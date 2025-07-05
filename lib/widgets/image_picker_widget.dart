import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(List<File>) onImagesSelected;
  final String? label;
  final double? height;
  final List<File>? initialImages;
  final bool allowMultiple;
  final int? maxImages;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.label = 'Tap to upload image',
    this.height,
    this.initialImages,
    this.allowMultiple = false,
    this.maxImages = 5,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _selectedImages = widget.initialImages ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: widget.height ?? (_selectedImages.isNotEmpty ? 200 : 120),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppConstants.x2),
          border: Border.all(color: AppColors.whiteWithAlpha(0.3)),
        ),
        child: _selectedImages.isNotEmpty
            ? widget.allowMultiple && _selectedImages.length > 1
                  ? _buildMultipleImagesView()
                  : _buildSingleImageView(_selectedImages.first)
            : _buildPlaceholderView(),
      ),
    );
  }

  Widget _buildSingleImageView(File image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.x2),
      child: Stack(
        children: [
          Image.file(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: AppConstants.x2,
            right: AppConstants.x2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppConstants.x4),
              ),
              child: IconButton(
                onPressed: () => _removeImage(0),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (widget.allowMultiple) ...[
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
        ],
      ),
    );
  }

  Widget _buildMultipleImagesView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.x2),
      child: Stack(
        children: [
          GridView.builder(
            padding: EdgeInsets.all(AppConstants.x2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.x1),
                    child: Image.file(
                      _selectedImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: AppConstants.x2,
            right: AppConstants.x2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppConstants.x4),
              ),
              child: IconButton(
                onPressed: _canAddMoreImages() ? _pickImage : null,
                icon: Icon(
                  Icons.add,
                  color: _canAddMoreImages() ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: AppColors.whiteWithAlpha(0.7),
        ),
        SizedBox(height: AppConstants.x2),
        Text(
          widget.label!,
          style: TextStyle(color: AppColors.whiteWithAlpha(0.7), fontSize: 16),
          textAlign: TextAlign.center,
        ),
        if (widget.allowMultiple) ...[
          SizedBox(height: AppConstants.x1),
          Text(
            'Max ${widget.maxImages} images',
            style: TextStyle(
              color: AppColors.whiteWithAlpha(0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  bool _canAddMoreImages() {
    return _selectedImages.length < (widget.maxImages ?? 5);
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
          final List<File> newImages = images
              .map((xFile) => File(xFile.path))
              .toList();
          final int availableSlots =
              (widget.maxImages ?? 5) - _selectedImages.length;
          final List<File> imagesToAdd = newImages
              .take(availableSlots)
              .toList();

          setState(() {
            _selectedImages.addAll(imagesToAdd);
          });
          widget.onImagesSelected(_selectedImages);
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
            _selectedImages = [selectedFile];
          });
          widget.onImagesSelected(_selectedImages);
        }
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected(_selectedImages);
  }
}
