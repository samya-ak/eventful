import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/location.dart';

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
      final String fileName = '$eventId.jpg';
      final String filePath = fileName;

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

  /// Fetch events with their associated images using query builder (LEFT JOIN equivalent)
  static Future<List<Map<String, dynamic>>> getEventsWithImages() async {
    try {
      // Fetch all events that are not deleted
      final events = await _client
          .from('events')
          .select(
            'event_id, event_name, event_description, created_at, updated_at, deleted_at',
          )
          .isFilter('deleted_at', null) // Only get non-deleted events
          .order('created_at', ascending: false);

      if (events.isEmpty) {
        return [];
      }

      // Get all event IDs
      final eventIds = events.map((e) => e['event_id']).toList();

      // Fetch all pictures for these events (polymorphic)
      final pictures = await _client
          .from('pictures')
          .select('picture_url, source_id')
          .eq('source_type', 'events')
          .inFilter('source_id', eventIds);

      // Group pictures by event_id
      final Map<String, List<String>> picturesByEventId = {};
      for (var picture in pictures) {
        final eventId = picture['source_id'];
        if (!picturesByEventId.containsKey(eventId)) {
          picturesByEventId[eventId] = [];
        }
        picturesByEventId[eventId]!.add(picture['picture_url']);
      }

      // Combine events with their images
      final result = events.map((event) {
        final eventId = event['event_id'];
        return {...event, 'images': picturesByEventId[eventId] ?? <String>[]};
      }).toList();

      return result;
    } catch (e) {
      print('Error fetching events with images: $e');
      throw Exception('Failed to fetch events with images: $e');
    }
  }

  /// Update an existing event
  static Future<Map<String, dynamic>?> updateEvent({
    required String eventId,
    required String name,
    String? description,
    List<String>? existingImageUrls, // Images that should remain
    List<File>? newImages, // New images to upload and add
  }) async {
    try {
      // Update the event record
      final eventResponse = await _client
          .from('events')
          .update({
            'event_name': name,
            'event_description': description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .select()
          .single();

      // Handle image updates
      if (existingImageUrls != null || newImages != null) {
        // Get current pictures from database
        final currentPictures = await _client
            .from('pictures')
            .select('picture_url')
            .eq('source_type', 'events')
            .eq('source_id', eventId);

        final currentImageUrls = currentPictures
            .map((p) => p['picture_url'] as String)
            .toList();

        // Find images to delete (images that are in database but not in existingImageUrls)
        final imagesToDelete = currentImageUrls
            .where((url) => existingImageUrls?.contains(url) != true)
            .toList();

        // Delete removed images
        if (imagesToDelete.isNotEmpty) {
          await _client
              .from('pictures')
              .delete()
              .eq('source_type', 'events')
              .eq('source_id', eventId)
              .inFilter('picture_url', imagesToDelete);
        }

        // Upload and add new images
        if (newImages != null && newImages.isNotEmpty) {
          final newImageUrls = await uploadEventImages(newImages);

          final pictureInserts = newImageUrls
              .map(
                (url) => {
                  'picture_url': url,
                  'source_type': 'events',
                  'source_id': eventId,
                },
              )
              .toList();

          await _client.from('pictures').insert(pictureInserts);
        }
      }

      return eventResponse;
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  /// Soft delete an event by setting deleted_at timestamp
  static Future<void> deleteEvent(String eventId) async {
    try {
      await _client
          .from('events')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('event_id', eventId);
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Upload multiple images and return their URLs
  static Future<List<String>> uploadEventImages(List<File> images) async {
    final List<String> imageUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        // Generate unique filename with timestamp
        final String fileName =
            'event_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final String filePath = 'events/$fileName';

        // Upload image to storage
        await _client.storage.from(_bucketName).upload(filePath, image);

        // Get public URL
        final String imageUrl = _client.storage
            .from(_bucketName)
            .getPublicUrl(filePath);

        imageUrls.add(imageUrl);
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading event images: $e');
      throw Exception('Failed to upload event images: $e');
    }
  }

  /// Create a new location with optional images
  static Future<Map<String, dynamic>?> createLocation({
    required String eventId,
    required String locationName,
    String? description,
    required double latitude,
    required double longitude,
    List<File>? images,
  }) async {
    try {
      // First, create the location record using PostgreSQL POINT format for coordinates
      final locationResponse = await _client
          .from('locations')
          .insert({
            'event_id': eventId,
            'location_name': locationName,
            'location_description': description,
            'coordinates':
                '($longitude,$latitude)', // PostgreSQL POINT format: (x,y)
          })
          .select()
          .single();

      final locationId = locationResponse['location_id'];

      // If there are images, upload them and create picture records
      if (images != null && images.isNotEmpty) {
        await _uploadLocationImages(images, locationId);
      }

      return locationResponse;
    } catch (e) {
      print('Error creating location: $e');
      throw Exception('Failed to create location: $e');
    }
  }

  /// Upload multiple images for a location
  static Future<void> _uploadLocationImages(
    List<File> images,
    String locationId,
  ) async {
    try {
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        // Generate unique filename with index
        final String fileName = '${locationId}_$i.jpg';
        final String filePath = 'locations/$fileName';

        // Upload image to storage
        await _client.storage.from(_bucketName).upload(filePath, image);

        // Get public URL
        final String imageUrl = _client.storage
            .from(_bucketName)
            .getPublicUrl(filePath);

        // Create picture record
        await _client.from('pictures').insert({
          'picture_url': imageUrl,
          'source_type': 'locations',
          'source_id': locationId,
        });
      }
    } catch (e) {
      print('Error uploading location images: $e');
      throw Exception('Failed to upload location images: $e');
    }
  }

  /// Get locations for a specific event with their images
  static Future<List<Map<String, dynamic>>> getLocationsForEvent(
    String eventId,
  ) async {
    try {
      // Fetch all locations for the event that are not deleted
      final locations = await _client
          .from('locations')
          .select(
            'location_id, location_name, location_description, coordinates, created_at, updated_at, deleted_at',
          )
          .eq('event_id', eventId)
          .isFilter('deleted_at', null) // Only get non-deleted locations
          .order('created_at', ascending: false);

      if (locations.isEmpty) {
        return [];
      }

      // Process coordinates and extract latitude/longitude
      final processedLocations = locations.map<Map<String, dynamic>>((
        location,
      ) {
        final coordinates = location['coordinates'];
        double latitude = 0.0;
        double longitude = 0.0;

        print(
          'Raw coordinates received: $coordinates (type: ${coordinates.runtimeType})',
        );

        // Parse coordinates based on the actual format received
        if (coordinates != null) {
          try {
            if (coordinates is String) {
              // Parse PostgreSQL POINT format: (x,y) where x=longitude, y=latitude
              final coordString = coordinates.replaceAll(RegExp(r'[()]'), '');
              final parts = coordString.split(',');
              if (parts.length == 2) {
                longitude = double.parse(parts[0].trim());
                latitude = double.parse(parts[1].trim());
              }
            } else if (coordinates is Map) {
              // Handle if coordinates come as a map
              longitude = (coordinates['x'] ?? 0.0).toDouble();
              latitude = (coordinates['y'] ?? 0.0).toDouble();
            } else if (coordinates is List && coordinates.length == 2) {
              // Handle if coordinates come as a list [x, y]
              longitude = coordinates[0].toDouble();
              latitude = coordinates[1].toDouble();
            }
          } catch (e) {
            print('Error parsing coordinates: $e');
          }
        }

        return {...location, 'latitude': latitude, 'longitude': longitude};
      }).toList();

      // Get all location IDs
      final locationIds = processedLocations
          .map((l) => l['location_id'])
          .toList();

      // Fetch all pictures for these locations
      final pictures = await _client
          .from('pictures')
          .select('picture_url, source_id')
          .eq('source_type', 'locations')
          .inFilter('source_id', locationIds);

      // Group pictures by location_id
      final Map<String, List<String>> picturesByLocationId = {};
      for (var picture in pictures) {
        final locationId = picture['source_id'];
        if (!picturesByLocationId.containsKey(locationId)) {
          picturesByLocationId[locationId] = [];
        }
        picturesByLocationId[locationId]!.add(picture['picture_url']);
      }

      // Combine locations with their images
      final result = processedLocations.map((location) {
        final locationId = location['location_id'];
        return {
          ...location,
          'images': picturesByLocationId[locationId] ?? <String>[],
        };
      }).toList();

      return result;
    } catch (e) {
      print('Error fetching locations for event: $e');
      throw Exception('Failed to fetch locations for event: $e');
    }
  }

  /// Update an existing location
  static Future<Map<String, dynamic>?> updateLocation({
    required String locationId,
    required String locationName,
    String? description,
    required double latitude,
    required double longitude,
    List<String>? existingImageUrls, // Images that should remain
    List<File>? newImages, // New images to upload and add
  }) async {
    try {
      // Update the location record
      final locationResponse = await _client
          .from('locations')
          .update({
            'location_name': locationName,
            'location_description': description,
            'coordinates': '($longitude,$latitude)', // PostgreSQL POINT format
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('location_id', locationId)
          .select()
          .single();

      // Handle image updates
      if (existingImageUrls != null || newImages != null) {
        // Get current pictures from database
        final currentPictures = await _client
            .from('pictures')
            .select('picture_url')
            .eq('source_type', 'locations')
            .eq('source_id', locationId);

        final currentImageUrls = currentPictures
            .map((p) => p['picture_url'] as String)
            .toList();

        // Find images to delete (images that are in database but not in existingImageUrls)
        final imagesToDelete = currentImageUrls
            .where((url) => existingImageUrls?.contains(url) != true)
            .toList();

        // Delete removed images
        if (imagesToDelete.isNotEmpty) {
          await _client
              .from('pictures')
              .delete()
              .eq('source_type', 'locations')
              .eq('source_id', locationId)
              .inFilter('picture_url', imagesToDelete);
        }

        // Upload and add new images
        if (newImages != null && newImages.isNotEmpty) {
          final newImageUrls = await uploadLocationImages(newImages);

          final pictureInserts = newImageUrls
              .map(
                (url) => {
                  'picture_url': url,
                  'source_type': 'locations',
                  'source_id': locationId,
                },
              )
              .toList();

          await _client.from('pictures').insert(pictureInserts);
        }
      }

      return locationResponse;
    } catch (e) {
      print('Error updating location: $e');
      throw Exception('Failed to update location: $e');
    }
  }

  /// Soft delete a location by setting deleted_at timestamp
  static Future<void> deleteLocation(String locationId) async {
    try {
      await _client
          .from('locations')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('location_id', locationId);
    } catch (e) {
      print('Error deleting location: $e');
      throw Exception('Failed to delete location: $e');
    }
  }

  /// Get a single location by ID with its images
  static Future<Location?> getLocationById(String locationId) async {
    try {
      // Fetch the location
      final locationData = await _client
          .from('locations')
          .select(
            'location_id, event_id, location_name, location_description, coordinates, created_at, updated_at, deleted_at',
          )
          .eq('location_id', locationId)
          .isFilter('deleted_at', null)
          .single();

      // Process coordinates
      final coordinates = locationData['coordinates'];
      double latitude = 0.0;
      double longitude = 0.0;

      if (coordinates != null) {
        try {
          if (coordinates is String) {
            final coordString = coordinates.replaceAll(RegExp(r'[()]'), '');
            final parts = coordString.split(',');
            if (parts.length == 2) {
              longitude = double.parse(parts[0].trim());
              latitude = double.parse(parts[1].trim());
            }
          }
        } catch (e) {
          print('Error parsing coordinates: $e');
        }
      }

      // Fetch pictures for this location
      final pictures = await _client
          .from('pictures')
          .select('picture_url')
          .eq('source_type', 'locations')
          .eq('source_id', locationId);

      final imageUrls = pictures
          .map((p) => p['picture_url'] as String)
          .toList();

      // Create Location object
      return Location(
        locationId: locationData['location_id'],
        eventId: locationData['event_id'],
        locationName: locationData['location_name'],
        description: locationData['location_description'],
        latitude: latitude,
        longitude: longitude,
        images: imageUrls,
        createdAt: locationData['created_at'] != null
            ? DateTime.parse(locationData['created_at'])
            : null,
        updatedAt: locationData['updated_at'] != null
            ? DateTime.parse(locationData['updated_at'])
            : null,
        deletedAt: locationData['deleted_at'] != null
            ? DateTime.parse(locationData['deleted_at'])
            : null,
      );
    } catch (e) {
      print('Error fetching location by ID: $e');
      return null;
    }
  }

  /// Get a single event by ID with its images
  static Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      // Fetch the event
      final eventData = await _client
          .from('events')
          .select(
            'event_id, event_name, event_description, created_at, updated_at, deleted_at',
          )
          .eq('event_id', eventId)
          .isFilter('deleted_at', null)
          .single();

      // Fetch pictures for this event
      final pictures = await _client
          .from('pictures')
          .select('picture_url')
          .eq('source_type', 'events')
          .eq('source_id', eventId);

      final imageUrls = pictures
          .map((p) => p['picture_url'] as String)
          .toList();

      return {...eventData, 'images': imageUrls};
    } catch (e) {
      print('Error fetching event by ID: $e');
      return null;
    }
  }

  /// Upload multiple images for locations and return their URLs
  static Future<List<String>> uploadLocationImages(List<File> images) async {
    final List<String> imageUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        // Generate unique filename with timestamp
        final String fileName =
            'location_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final String filePath = 'locations/$fileName';

        // Upload image to storage
        await _client.storage.from(_bucketName).upload(filePath, image);

        // Get public URL
        final String imageUrl = _client.storage
            .from(_bucketName)
            .getPublicUrl(filePath);

        imageUrls.add(imageUrl);
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading location images: $e');
      throw Exception('Failed to upload location images: $e');
    }
  }
}
