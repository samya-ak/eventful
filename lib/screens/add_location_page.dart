import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../widgets/location_form.dart';
import '../services/supabase_service.dart';

class AddLocationPage extends StatefulWidget {
  final String eventId;

  const AddLocationPage({super.key, required this.eventId});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  bool _isSubmitting = false;

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
      body: LocationForm(
        isSubmitting: _isSubmitting,
        submitButtonText: AppStrings.confirmButtonText,
        onSubmit: _addLocation,
      ),
    );
  }

  Future<void> _addLocation(
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
      // For adding new locations, we only use newImages (existingImages will be empty)
      final locationData = await SupabaseService.createLocation(
        eventId: widget.eventId,
        locationName: locationName,
        description: description.isNotEmpty ? description : null,
        latitude: latitude,
        longitude: longitude,
        images: newImages.isNotEmpty ? newImages : null,
      );

      if (mounted && locationData != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$locationName" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding location: ${e.toString()}'),
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
