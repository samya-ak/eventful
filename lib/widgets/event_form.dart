import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../widgets/enhanced_image_picker.dart';
import '../models/event.dart';

class EventForm extends StatefulWidget {
  final Event? initialEvent;
  final Function(
    String name,
    String description,
    List<File> images,
    List<String> existingImageUrls,
  )
  onSubmit;
  final bool isSubmitting;
  final String submitButtonText;

  const EventForm({
    super.key,
    this.initialEvent,
    required this.onSubmit,
    this.isSubmitting = false,
    this.submitButtonText = 'Create Event',
  });

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      _eventNameController.text = widget.initialEvent!.name;
      _eventDescriptionController.text = widget.initialEvent!.description;
      // Store existing image URLs
      _existingImageUrls = widget.initialEvent!.images ?? [];
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _eventNameController.text.trim(),
        _eventDescriptionController.text.trim(),
        _selectedImages,
        _existingImageUrls,
      );
    }
  }

  String _getLoadingText() {
    // Generate contextual loading text based on the submit button text
    if (widget.submitButtonText.toLowerCase().contains('update')) {
      return 'Updating event...';
    } else if (widget.submitButtonText.toLowerCase().contains('create')) {
      return 'Creating event...';
    } else if (widget.submitButtonText.toLowerCase().contains('add')) {
      return 'Creating event...';
    } else {
      return 'Processing...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  EnhancedImagePicker(
                    onImagesChanged:
                        (List<File> newImages, List<String> existingImages) {
                          setState(() {
                            _selectedImages = newImages;
                            _existingImageUrls = existingImages;
                          });
                        },
                    label: AppStrings.uploadImageLabel,
                    existingImageUrls: _existingImageUrls,
                    initialNewImages: _selectedImages,
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
        // Fixed Submit Button
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
            onPressed: widget.isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: AppConstants.x3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.x2),
              ),
            ),
            child: widget.isSubmitting
                ? Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                        Text(
                          _getLoadingText(),
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: AppConstants.x3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    widget.submitButtonText,
                    style: TextStyle(
                      fontSize: AppConstants.x3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
