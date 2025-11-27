import 'package:firebase_database/firebase_database.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';

abstract class LocationRepository {
  Future<void> updateChildLocation(String childId, LocationData location);

  /// Lắng nghe vị trí hiện tại của 1 đứa trẻ
  Stream<LocationData> watchChildLocation(String childId);

  /// Lấy lịch sử di chuyển
  Future<List<LocationData>> getLocationHistory(String childId);
}

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Future<void> updateChildLocation(String childId, LocationData location) async {
    try {
      print("🚀 updateChildLocation called: $childId "
          "${location.latitude}, ${location.longitude}");

      await _database.ref('locations/$childId/current').set({
        ...location.toJson(),
        'updatedAt': ServerValue.timestamp,
      });

      print("✅ current saved");

      await _database
          .ref('locations/$childId/history')
          .push()
          .set(location.toJson());

      print("✅ history saved");
    } catch (e) {
      print("❌ updateChildLocation error: $e");
      throw Exception('Failed to update location: $e');
    }
  }


  @override
  Stream<LocationData> watchChildLocation(String childId) {
    return _database
        .ref('locations/$childId/current')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return LocationData.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      throw Exception('Location not found');
    });
  }

  @override
  Future<List<LocationData>> getLocationHistory(String childId) async {
    try {
      final snapshot =
      await _database.ref('locations/$childId/history').get();

      if (!snapshot.exists) return [];

      final List<LocationData> list = [];

      for (final data in snapshot.children) {
        final json = Map<String, dynamic>.from(data.value as Map);
        list.add(LocationData.fromJson(json));
      }

      return list;
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }
}
