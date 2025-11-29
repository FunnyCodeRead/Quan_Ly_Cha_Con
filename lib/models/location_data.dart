import 'dart:math' as math;
import 'package:latlong2/latlong.dart' as osm;

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

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  /// LatLng dùng cho flutter_map / OSM
  osm.LatLng get latLng => osm.LatLng(latitude, longitude);

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
    timestamp: (json['timestamp'] as num).toInt(),
  );

  /// Tính khoảng cách giữa 2 điểm (km)
  double distanceTo(LocationData other) {
    const double p = 0.017453292519943295; // pi/180
    final double a = 0.5 -
        math.cos((other.latitude - latitude) * p) / 2 +
        math.cos(latitude * p) *
            math.cos(other.latitude * p) *
            (1 - math.cos((other.longitude - longitude) * p)) / 2;

    return 12742 * math.asin(math.sqrt(a)); // 2*R; R=6371km
  }
}
