import 'package:geolocator/geolocator.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';
import 'dart:async';

abstract class LocationServiceInterface {
  Future<bool> requestLocationPermission();
  Future<LocationData?> getCurrentLocation();
  Stream<LocationData> getLocationStream();
  Future<void> startLocationUpdates();
  Future<void> stopLocationUpdates();
}

class LocationServiceImpl implements LocationServiceInterface {
  static const int minDistance = 50; // 50 meters
  StreamSubscription<Position>? _positionSubscription;

  @override
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<LocationData?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  @override
  Stream<LocationData> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: minDistance, // Update setiap 50m
      ),
    ).map((position) => LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  Future<void> startLocationUpdates() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: minDistance,
      ),
    ).listen((position) {
      // Bạn có thể xử lý khi nhận location ở đây
      print("New location: ${position.latitude}, ${position.longitude}");
    });
  }


  @override
  Future<void> stopLocationUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

}
