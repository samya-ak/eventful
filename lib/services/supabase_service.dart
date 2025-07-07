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
      // Fetch all events
      final events = await _client
          .from('events')
          .select(
            'event_id, event_name, event_description, created_at, updated_at',
          )
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
      // Fetch all locations for the event
      final locations = await _client
          .from('locations')
          .select(
            'location_id, location_name, location_description, coordinates, created_at, updated_at',
          )
          .eq('event_id', eventId)
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
}
