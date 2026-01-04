import 'dart:math';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final int timestamp; // ms since epoch

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return LocationData(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: _toDouble(json['accuracy']),
      timestamp: _toInt(json['timestamp']),
    );
  }

  /// distance (km) using Haversine
  double distanceTo(LocationData other) {
    const r = 6371.0;
    final dLat = _degToRad(other.latitude - latitude);
    final dLng = _degToRad(other.longitude - longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(latitude)) *
            cos(_degToRad(other.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * pi / 180.0;
}
