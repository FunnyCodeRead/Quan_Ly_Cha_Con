import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';

abstract class LocationRepository {
  Future<void> updateMyLocation(LocationData location);

  Stream<LocationData> watchChildLocation(String childId);

  Future<List<LocationData>> getLocationHistory(String childId);
}

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("Chưa đăng nhập -> không thể gửi vị trí");
    }
    return uid;
  }

  @override
  Future<void> updateMyLocation(LocationData location) async {
    final uid = _requireUid();

    try {
      print("🚀 updateMyLocation called: $uid "
          "${location.latitude}, ${location.longitude}");

      await _database.ref('locations/$uid/current').set({
        ...location.toJson(),
        'updatedAt': ServerValue.timestamp,
      });

      await _database
          .ref('locations/$uid/history')
          .push()
          .set(location.toJson());

      print("✅ location saved for $uid");
    } catch (e) {
      print("❌ updateMyLocation error: $e");
      throw Exception('Failed to update location: $e');
    }
  }

  @override
  Stream<LocationData> watchChildLocation(String childId) {
    return _database
        .ref('locations/$childId/current')
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
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
        if (data.value is Map) {
          final json = Map<String, dynamic>.from(data.value as Map);
          list.add(LocationData.fromJson(json));
        }
      }
      return list;
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }
}
