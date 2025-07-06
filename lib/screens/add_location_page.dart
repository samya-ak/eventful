import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../widgets/image_picker_widget.dart';
import '../services/supabase_service.dart';

class AddLocationPage extends StatefulWidget {
  final String eventId;

  const AddLocationPage({super.key, required this.eventId});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  final MapController _mapController = MapController();

  List<File> _selectedImages = [];
  LatLng _selectedLocation = const LatLng(
    27.7172, // Kathmandu, Nepal latitude
    85.3240, // Kathmandu, Nepal longitude
  ); // Default location (Kathmandu, Nepal)
  bool _isSubmitting = false;
  bool _isLoadingCurrentLocation = true;

  // Default location (Kathmandu, Nepal)
  static const LatLng _defaultLocation = LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _locationDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      print('DEBUG: Checking location service status...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('DEBUG: Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        print('DEBUG: Location service is not enabled, using default location');
        setState(() {
          _selectedLocation = _defaultLocation;
          _isLoadingCurrentLocation = false;
        });
        _showLocationMessage(
          'Location service is disabled. Using Kathmandu as default location.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_defaultLocation, 15.0);
        });
        return;
      }

      print('DEBUG: Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('DEBUG: Current permission: $permission');

      if (permission == LocationPermission.denied) {
        print('DEBUG: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('DEBUG: Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          print('DEBUG: Location permission denied, using default location');
          setState(() {
            _selectedLocation = _defaultLocation;
            _isLoadingCurrentLocation = false;
          });
          _showLocationMessage(
            'Location permission denied. Using Kathmandu as default location.',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(_defaultLocation, 15.0);
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
          'DEBUG: Location permission denied forever, using default location',
        );
        setState(() {
          _selectedLocation = _defaultLocation;
          _isLoadingCurrentLocation = false;
        });
        _showLocationMessage(
          'Location permission permanently denied. Using Kathmandu as default location.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_defaultLocation, 15.0);
        });
        return;
      }

      print('DEBUG: Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
        'DEBUG: Got position - Lat: ${position.latitude}, Lng: ${position.longitude}',
      );
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = currentLocation;
        _isLoadingCurrentLocation = false;
      });

      _showLocationMessage('Current location detected successfully!');

      // Wait for next frame before moving map to ensure it's rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentLocation, 15.0);
      });
    } on MissingPluginException catch (e) {
      print(
        'DEBUG: MissingPluginException - Location plugin not available: $e',
      );
      setState(() {
        _selectedLocation = _defaultLocation;
        _isLoadingCurrentLocation = false;
      });
      _showLocationMessage(
        'Location plugin not available. Please restart the app or tap the location icon to manually select your location.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_defaultLocation, 15.0);
      });
    } catch (e) {
      print('DEBUG: Error getting location: $e');
      // Use default location if current location fails
      setState(() {
        _selectedLocation = _defaultLocation;
        _isLoadingCurrentLocation = false;
      });
      _showLocationMessage(
        'Failed to get current location. Using Kathmandu as default location. Tap the map to select your location.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_defaultLocation, 15.0);
      });
    }
  }

  void _showLocationMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  Future<void> _submitLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save location to Supabase
      final locationData = await SupabaseService.createLocation(
        eventId: widget.eventId,
        locationName: _locationNameController.text.trim(),
        description: _locationDescriptionController.text.trim().isNotEmpty
            ? _locationDescriptionController.text.trim()
            : null,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (mounted && locationData != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location "${_locationNameController.text}" added successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding location: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
        title: const Text(
          AppStrings.addLocationTitle,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppConstants.x5,
          ),
        ),
      ),
      body: Column(
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
                    ImagePickerWidget(
                      onImagesSelected: (List<File> images) {
                        setState(() {
                          _selectedImages = images;
                        });
                      },
                      label: 'Tap to upload location images',
                      initialImages: _selectedImages,
                      allowMultiple: true,
                      maxImages: 5,
                    ),
                    const SizedBox(height: AppConstants.x4),

                    // Map Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.selectLocationOnMapText,
                              style: TextStyle(
                                color: AppColors.whiteWithAlpha(0.7),
                                fontSize: AppConstants.x4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isLoadingCurrentLocation)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppConstants.x2,
                                ),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.whiteWithAlpha(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            // Debug button to retry location
                            IconButton(
                              onPressed: _isLoadingCurrentLocation
                                  ? null
                                  : _getCurrentLocation,
                              icon: Icon(
                                Icons.my_location,
                                color: _isLoadingCurrentLocation
                                    ? AppColors.whiteWithAlpha(0.3)
                                    : AppColors.whiteWithAlpha(0.7),
                                size: 20,
                              ),
                              tooltip: 'Get current location',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.x2),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppConstants.x2,
                            ),
                            border: Border.all(
                              color: AppColors.whiteWithAlpha(0.3),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _isLoadingCurrentLocation
                              ? Container(
                                  color: AppColors.secondary,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.whiteWithAlpha(0.7),
                                              ),
                                        ),
                                        const SizedBox(height: AppConstants.x2),
                                        Text(
                                          'Getting current location...',
                                          style: TextStyle(
                                            color: AppColors.whiteWithAlpha(
                                              0.7,
                                            ),
                                            fontSize: AppConstants.x3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Stack(
                                  children: [
                                    FlutterMap(
                                      key: ValueKey(
                                        _selectedLocation.toString(),
                                      ),
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
                                          userAgentPackageName:
                                              'com.example.mattya',
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
                                      right: 10,
                                      top: 10,
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                final zoom =
                                                    _mapController.camera.zoom;
                                                _mapController.move(
                                                  _selectedLocation,
                                                  zoom + 1,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.add,
                                                color: AppColors.whiteWithAlpha(
                                                  0.8,
                                                ),
                                                size: 20,
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                final zoom =
                                                    _mapController.camera.zoom;
                                                _mapController.move(
                                                  _selectedLocation,
                                                  zoom - 1,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.remove,
                                                color: AppColors.whiteWithAlpha(
                                                  0.8,
                                                ),
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
                        if (!_isLoadingCurrentLocation)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppConstants.x2,
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

          // Confirm Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.x4),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.x4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.x2),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check),
                        const SizedBox(width: AppConstants.x2),
                        Text(
                          AppStrings.confirmButtonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppConstants.x4,
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
