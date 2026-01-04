import '../entities/location_data.dart';

abstract class LocationRepository {
  Future<void> updateMyLocation(LocationData location);

  Stream<LocationData> watchChildLocation(String childId);

  Future<List<LocationData>> getLocationHistory(String childId);
}
