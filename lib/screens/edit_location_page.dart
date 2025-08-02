import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/location_form.dart';
import '../services/supabase_service.dart';
import '../models/location.dart';

class EditLocationPage extends StatefulWidget {
  final String eventId;
  final Location location;

  const EditLocationPage({
    super.key,
    required this.eventId,
    required this.location,
  });

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  bool _isSubmitting = false;
  bool _isLoading = true;
  Location? _currentLocation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
  }

  Future<void> _fetchLocationData() async {
    try {
      final freshLocation = await SupabaseService.getLocationById(
        widget.location.locationId!,
      );

      if (mounted) {
        setState(() {
          _currentLocation = freshLocation;
          _isLoading = false;
          if (freshLocation == null) {
            _errorMessage = 'Location not found or has been deleted.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading location data: $e';
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
        title: Text(
          'Edit Location',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppConstants.x5,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.x4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.whiteWithAlpha(0.7),
              ),
              SizedBox(height: AppConstants.x4),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppColors.whiteWithAlpha(0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.x4),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchLocationData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentLocation == null) {
      return const Center(
        child: Text(
          'Location not found',
          style: TextStyle(color: AppColors.white),
        ),
      );
    }

    return LocationForm(
      initialLocation: _currentLocation!,
      isSubmitting: _isSubmitting,
      submitButtonText: 'Update Location',
      onSubmit: _updateLocation,
    );
  }

  Future<void> _updateLocation(
    String locationName,
    String description,
    double latitude,
    double longitude,
    List<File> newImages,
    List<String> existingImages,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update the location with incremental image changes
      await SupabaseService.updateLocation(
        locationId: _currentLocation!.locationId!,
        locationName: locationName,
        description: description.isEmpty ? null : description,
        latitude: latitude,
        longitude: longitude,
        existingImageUrls: existingImages, // Images that should remain
        newImages: newImages.isNotEmpty ? newImages : null, // New images to add
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update location: $e'),
            backgroundColor: Colors.red,
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
}
