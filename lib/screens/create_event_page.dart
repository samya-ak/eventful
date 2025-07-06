import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../widgets/image_picker_widget.dart';
import '../services/supabase_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
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
          AppStrings.createNewEventTitle,
          style: const TextStyle(
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
              padding: EdgeInsets.all(AppConstants.x4),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name Field
                    TextFormField(
                      controller: _eventNameController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        labelText: AppStrings.eventNameLabel,
                        labelStyle: TextStyle(
                          color: AppColors.whiteWithAlpha(0.7),
                        ),
                        alignLabelWithHint: true,
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
                          borderSide: BorderSide(
                            color: AppColors.button,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.eventNameRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppConstants.x4),

                    // Event Description Field
                    TextFormField(
                      controller: _eventDescriptionController,
                      style: const TextStyle(color: AppColors.white),
                      maxLines: 6,
                      minLines: 6,
                      decoration: InputDecoration(
                        labelText: AppStrings.eventDescriptionLabel,
                        labelStyle: TextStyle(
                          color: AppColors.whiteWithAlpha(0.7),
                        ),
                        alignLabelWithHint: true,
                        hintText: AppStrings.eventDescriptionHint,
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
                          borderSide: BorderSide(
                            color: AppColors.button,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppConstants.x4),

                    // Image Upload Section
                    ImagePickerWidget(
                      onImagesSelected: (List<File> images) {
                        setState(() {
                          _selectedImages = images;
                        });
                      },
                      label: AppStrings.uploadImageLabel,
                      initialImages: _selectedImages,
                      allowMultiple: false, // Single image for events
                    ),
                    SizedBox(
                      height: AppConstants.x8,
                    ), // Extra space before bottom button
                  ],
                ),
              ),
            ),
          ),
          // Fixed Confirm Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppConstants.x4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border(
                top: BorderSide(color: AppColors.whiteWithAlpha(0.1)),
              ),
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: AppConstants.x3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.x2),
                ),
              ),
              child: _isSubmitting
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(
                          (0.95 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.x2),
                      ),
                      child: Row(
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
                          const Text(
                            'Creating Event...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      AppStrings.confirmButtonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get the selected image (single image mode)
        final File? selectedImage = _selectedImages.isNotEmpty
            ? _selectedImages.first
            : null;

        // Create event in Supabase
        final eventData = await SupabaseService.createEvent(
          name: _eventNameController.text.trim(),
          description: _eventDescriptionController.text.trim().isEmpty
              ? null
              : _eventDescriptionController.text.trim(),
          image: selectedImage,
        );

        if (eventData != null) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Event "${eventData['event_name']}" created successfully!',
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );

            // Return to previous screen
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating event: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
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
}
