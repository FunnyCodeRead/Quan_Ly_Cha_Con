class ChildLocation {
  final double lat;
  final double lng;
  final String? name;
  final int timestamp;

  ChildLocation({
    this.lat = 0.0,
    this.lng = 0.0,
    this.name = '',
    this.timestamp = 0,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'name': name,
      'timestamp': timestamp,
    };
  }

  // Create from JSON
  factory ChildLocation.fromJson(Map<String, dynamic> json) {
    return ChildLocation(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String?,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  // Copy with method
  ChildLocation copyWith({
    double? lat,
    double? lng,
    String? name,
    int? timestamp,
  }) {
    return ChildLocation(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'ChildLocation(lat: $lat, lng: $lng, name: $name, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChildLocation &&
              runtimeType == other.runtimeType &&
              lat == other.lat &&
              lng == other.lng &&
              name == other.name &&
              timestamp == other.timestamp;

  @override
  int get hashCode =>
      lat.hashCode ^
      lng.hashCode ^
      name.hashCode ^
      timestamp.hashCode;
}