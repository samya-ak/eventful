import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'event-images';

  /// Create a new event with optional image
  static Future<Map<String, dynamic>?> createEvent({
    required String name,
    String? description,
    File? image,
  }) async {
    try {
      // First, create the event record
      final eventResponse = await _client
          .from('events')
          .insert({'event_name': name, 'event_description': description})
          .select()
          .single();

      final eventId = eventResponse['event_id'];

      // If there's an image, upload it and create picture record
      if (image != null) {
        await _uploadEventImage(image, eventId);
      }

      return eventResponse;
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  /// Upload image to Supabase storage and create picture record
  static Future<void> _uploadEventImage(File image, String eventId) async {
    try {
      // Generate unique filename
      final String fileName = '${eventId}.jpg';
      final String filePath = '$fileName';

      // Upload image to storage
      await _client.storage.from(_bucketName).upload(filePath, image);

      // Get public URL
      final String imageUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      // Create picture record
      await _client.from('pictures').insert({
        'picture_url': imageUrl,
        'source_type': 'events',
        'source_id': eventId,
      });
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Create storage bucket if it doesn't exist
  static Future<void> createBucketIfNotExists() async {
    try {
      // Try to get bucket info
      await _client.storage.getBucket(_bucketName);
      print('Bucket "$_bucketName" already exists');
    } catch (e) {
      print('Bucket "$_bucketName" not found, attempting to create...');
      // If bucket doesn't exist, create it
      try {
        await _client.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5MB',
          ),
        );
        print('Successfully created bucket "$_bucketName"');
      } catch (createError) {
        print('Error creating bucket: $createError');
        // Don't throw here, let the upload method handle bucket creation
      }
    }
  }

  /// Check if Supabase is properly initialized and connected
  static Future<bool> checkConnection() async {
    try {
      // Try a simple query to test connection
      await _client.from('events').select('event_id').limit(1);
      return true;
    } catch (e) {
      print('Supabase connection check failed: $e');
      return false;
    }
  }
}
