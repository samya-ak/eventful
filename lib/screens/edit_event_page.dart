import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/event_form.dart';
import '../services/supabase_service.dart';
import '../models/event.dart';

class EditEventPage extends StatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  bool _isSubmitting = false;
  bool _isLoading = true;
  Map<String, dynamic>? _currentEventData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  Future<void> _fetchEventData() async {
    try {
      final freshEventData = await SupabaseService.getEventById(
        widget.event.eventId!,
      );

      if (mounted) {
        setState(() {
          _currentEventData = freshEventData;
          _isLoading = false;
          if (freshEventData == null) {
            _errorMessage = 'Event not found or has been deleted.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading event data: $e';
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
          'Edit Event',
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
                  _fetchEventData();
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

    if (_currentEventData == null) {
      return const Center(
        child: Text(
          'Event not found',
          style: TextStyle(color: AppColors.white),
        ),
      );
    }

    // Create Event object from fresh data
    final freshEvent = Event.fromJson(_currentEventData!);

    return EventForm(
      initialEvent: freshEvent,
      isSubmitting: _isSubmitting,
      submitButtonText: 'Update Event',
      onSubmit: _updateEvent,
    );
  }

  Future<void> _updateEvent(
    String name,
    String description,
    List<File> newImages,
    List<String> existingImages,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update the event with incremental image changes
      await SupabaseService.updateEvent(
        eventId: _currentEventData!['event_id'],
        name: name,
        description: description,
        existingImageUrls: existingImages, // Images that should remain
        newImages: newImages.isNotEmpty ? newImages : null, // New images to add
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update event: $e'),
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
