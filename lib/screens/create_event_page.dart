import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../widgets/event_form.dart';
import '../services/supabase_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
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
        title: Text(
          AppStrings.createNewEventTitle,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppConstants.x5,
          ),
        ),
      ),
      body: EventForm(
        isSubmitting: _isSubmitting,
        submitButtonText: 'Create Event',
        onSubmit: _createEvent,
      ),
    );
  }

  Future<void> _createEvent(
    String name,
    String description,
    List<File> newImages,
    List<String> existingImages,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // For creating new events, we only use newImages (existingImages will be empty)
      File? imageFile = newImages.isNotEmpty ? newImages.first : null;

      await SupabaseService.createEvent(
        name: name,
        description: description,
        image: imageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: $e'),
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
