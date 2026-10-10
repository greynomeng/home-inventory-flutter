class Location {
  final String? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Location({this.id, required this.name, this.createdAt, this.updatedAt});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: json['name'] as String,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  Location copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'Location(id: $id, name: $name)';
}
