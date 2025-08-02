import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../widgets/enhanced_image_picker.dart';
import '../models/location.dart';

class LocationForm extends StatefulWidget {
  final Location? initialLocation;
  final Function(
    String name,
    String description,
    double latitude,
    double longitude,
    List<File> newImages,
    List<String> existingImages,
  )
  onSubmit;
  final bool isSubmitting;
  final String submitButtonText;

  const LocationForm({
    super.key,
    this.initialLocation,
    required this.onSubmit,
    this.isSubmitting = false,
    this.submitButtonText = 'Add Location',
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  final MapController _mapController = MapController();

  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  LatLng _selectedLocation = const LatLng(
    27.7172,
    85.3240,
  ); // Default to Kathmandu

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _locationNameController.text = widget.initialLocation!.locationName;
      _locationDescriptionController.text =
          widget.initialLocation!.description ?? '';
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      // Store existing image URLs
      _existingImageUrls = widget.initialLocation!.images ?? [];
    }
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _locationDescriptionController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  String _getLoadingText() {
    // Generate contextual loading text based on the submit button text
    if (widget.submitButtonText.toLowerCase().contains('update')) {
      return 'Updating location...';
    } else if (widget.submitButtonText.toLowerCase().contains('add')) {
      return 'Adding location...';
    } else if (widget.submitButtonText.toLowerCase().contains('confirm')) {
      return 'Adding location...';
    } else {
      return 'Processing...';
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _locationNameController.text.trim(),
        _locationDescriptionController.text.trim(),
        _selectedLocation.latitude,
        _selectedLocation.longitude,
        _selectedImages,
        _existingImageUrls,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.x4),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Name Field
                  TextFormField(
                    controller: _locationNameController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: AppStrings.locationNameLabel,
                      labelStyle: TextStyle(
                        color: AppColors.whiteWithAlpha(0.7),
                      ),
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                        borderSide: BorderSide(
                          color: AppColors.whiteWithAlpha(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                        borderSide: BorderSide(
                          color: AppColors.whiteWithAlpha(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                        borderSide: const BorderSide(
                          color: AppColors.button,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.locationNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.x4),

                  // Location Description Field
                  TextFormField(
                    controller: _locationDescriptionController,
                    style: const TextStyle(color: AppColors.white),
                    maxLines: 4,
                    minLines: 4,
                    decoration: InputDecoration(
                      labelText: AppStrings.locationDescriptionLabel,
                      labelStyle: TextStyle(
                        color: AppColors.whiteWithAlpha(0.7),
                      ),
                      alignLabelWithHint: true,
                      hintText: AppStrings.locationDescriptionHint,
                      hintStyle: TextStyle(
                        color: AppColors.whiteWithAlpha(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                        borderSide: BorderSide(
                          color: AppColors.whiteWithAlpha(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                        borderSide: BorderSide(
                          color: AppColors.whiteWithAlpha(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                        borderSide: const BorderSide(
                          color: AppColors.button,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.x4),

                  // Image Upload Section
                  EnhancedImagePicker(
                    onImagesChanged:
                        (List<File> newImages, List<String> existingImages) {
                          setState(() {
                            _selectedImages = newImages;
                            _existingImageUrls = existingImages;
                          });
                        },
                    label: 'Tap to upload location images',
                    existingImageUrls: _existingImageUrls,
                    initialNewImages: _selectedImages,
                    allowMultiple: true,
                    maxImages: 5,
                  ),
                  const SizedBox(height: AppConstants.x4),

                  // Map Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.selectLocationOnMapText,
                        style: TextStyle(
                          color: AppColors.whiteWithAlpha(0.7),
                          fontSize: AppConstants.x4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppConstants.x2),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppConstants.x2),
                          border: Border.all(
                            color: AppColors.whiteWithAlpha(0.3),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              key: ValueKey(_selectedLocation.toString()),
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation,
                                initialZoom: 15.0,
                                minZoom: 1.0,
                                maxZoom: 22.0,
                                onTap: _onMapTap,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.mattya',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Zoom controls
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(6),
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
                                        size: 20,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(6),
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
                                        size: 20,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.x2),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.x3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppConstants.x2),
                          border: Border.all(
                            color: AppColors.whiteWithAlpha(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.locationSelectedText}:',
                              style: TextStyle(
                                color: AppColors.whiteWithAlpha(0.7),
                                fontSize: AppConstants.x3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppConstants.x1),
                            Text(
                              'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: AppColors.whiteWithAlpha(0.6),
                                fontSize: AppConstants.x3,
                              ),
                            ),
                            Text(
                              'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: AppColors.whiteWithAlpha(0.6),
                                fontSize: AppConstants.x3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.x6),
                ],
              ),
            ),
          ),
        ),
        // Fixed Submit Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.x4),
          child: ElevatedButton(
            onPressed: widget.isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppConstants.x3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.x2),
              ),
            ),
            child: widget.isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: AppConstants.x2),
                      Text(
                        _getLoadingText(),
                        style: const TextStyle(
                          fontSize: AppConstants.x3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    widget.submitButtonText,
                    style: const TextStyle(
                      fontSize: AppConstants.x3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
