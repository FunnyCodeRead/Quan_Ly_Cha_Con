import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  LocationRepositoryImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

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

    await _database.ref('locations/$uid/current').set({
      ...location.toJson(),
      'updatedAt': ServerValue.timestamp,
    });

    await _database.ref('locations/$uid/history').push().set(location.toJson());
  }

  @override
  Stream<LocationData> watchChildLocation(String childId) {
    return _database.ref('locations/$childId/current').onValue.map((event) {
      final snap = event.snapshot;
      if (snap.exists && snap.value is Map) {
        return LocationData.fromJson(Map<String, dynamic>.from(snap.value as Map));
      }
      throw Exception('Location not found');
    });
  }

  @override
  Future<List<LocationData>> getLocationHistory(String childId) async {
    final snapshot = await _database.ref('locations/$childId/history').get();
    if (!snapshot.exists) return [];

    final list = <LocationData>[];
    for (final data in snapshot.children) {
      if (data.value is Map) {
        final json = Map<String, dynamic>.from(data.value as Map);
        list.add(LocationData.fromJson(json));
      }
    }

    // sort by timestamp to be safe
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}
