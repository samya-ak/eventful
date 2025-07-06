class Event {
  final String? eventId;
  final String name;
  final String description;
  final List<String>? images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Event({
    this.eventId,
    required this.name,
    required this.description,
    this.images,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating from database JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] as String?,
      name: json['event_name'] as String,
      description: json['event_description'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_name': name,
      'event_description': description,
      'images': images,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper getter for the first image
  String? get primaryImage => images?.isNotEmpty == true ? images!.first : null;
}
