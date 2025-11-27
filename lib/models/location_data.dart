import 'dart:math' as Math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final int timestamp;
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    timestamp: json['timestamp'] as int,
  );

  /// Tính khoảng cách giữa 2 điểm (km)
  double distanceTo(LocationData other) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        Math.cos((other.latitude - latitude) * p) / 2 +
        Math.cos(latitude * p) *
            Math.cos(other.latitude * p) *
            (1 - Math.cos((other.longitude - longitude) * p)) / 2;

    return 12742 * Math.asin(Math.sqrt(a));
  }
}
