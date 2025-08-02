class Location {
  final String? locationId;
  final String eventId;
  final String locationName;
  final String? description;
  final double latitude;
  final double longitude;
  final List<String>? images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Location({
    this.locationId,
    required this.eventId,
    required this.locationName,
    this.description,
    required this.latitude,
    required this.longitude,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Factory constructor for creating from database JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['location_id'] as String?,
      eventId: json['event_id'] as String,
      locationName: json['location_name'] as String,
      description: json['location_description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'event_id': eventId,
      'location_name': locationName,
      'location_description': description,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // Helper getter for the first image
  String? get primaryImage => images?.isNotEmpty == true ? images!.first : null;
}
