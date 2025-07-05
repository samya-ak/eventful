class Event {
  final String name;
  final String description;

  const Event({required this.name, required this.description});

  // Factory constructor for creating from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}
