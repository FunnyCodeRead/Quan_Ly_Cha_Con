import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';

enum LocationSharingStatus { idle, sharing, paused, error }

class ParentLocationVm extends ChangeNotifier {
  final LocationRepository _repo;

  final Map<String, LocationData> _childrenLocations = {};
  final Map<String, List<LocationData>> _childrenTrails = {};
  final Map<String, StreamSubscription<LocationData>> _subs = {};

  String _errorMessage = '';
  LocationSharingStatus _status = LocationSharingStatus.idle;

  ParentLocationVm(this._repo);

  Map<String, LocationData> get childrenLocations => _childrenLocations;
  Map<String, List<LocationData>> get childrenTrails => _childrenTrails;
  String get errorMessage => _errorMessage;
  LocationSharingStatus get status => _status;

  Stream<LocationData> watchChildLocation(String childId) => _repo.watchChildLocation(childId);

  Future<void> watchAllChildren(List<String> childIds) async {
    _status = LocationSharingStatus.sharing;
    notifyListeners();

    try {
      for (final childId in childIds) {
        if (_subs.containsKey(childId)) continue;

        _childrenTrails.putIfAbsent(childId, () => []);

        final sub = _repo.watchChildLocation(childId).listen(
              (loc) {
            if (!_isValidLocation(loc)) return;

            _childrenLocations[childId] = loc;

            final trail = _childrenTrails[childId]!;
            if (trail.isEmpty || trail.last.timestamp != loc.timestamp) {
              trail.add(loc);
              if (trail.length > 300) {
                trail.removeRange(0, trail.length - 300);
              }
            }
            notifyListeners();
          },
          onError: (e) => _setError('Lỗi theo dõi $childId: $e'),
        );

        _subs[childId] = sub;
      }
    } catch (e) {
      _setError('Lỗi theo dõi con: $e');
    }
  }

  Future<void> refreshWatching(List<String> newChildIds) async {
    final oldIds = _subs.keys.toList();
    for (final id in oldIds) {
      if (!newChildIds.contains(id)) {
        await stopWatchingChild(id);
      }
    }
    await watchAllChildren(newChildIds);
  }


  // ========== STATS ==========
  Map<String, dynamic> getChildLocationStats(String childId) {
    final trail = _childrenTrails[childId] ?? [];
    if (trail.isEmpty) return {};

    double totalDistance = 0;
    for (int i = 1; i < trail.length; i++) {
      totalDistance += trail[i - 1].distanceTo(trail[i]);
    }

    return {
      'totalPoints': trail.length,
      'totalDistance': totalDistance,
      'firstLocation': trail.first,
      'lastLocation': trail.last,
      'timeSpan': trail.last.timestamp - trail.first.timestamp,
    };
  }

  bool isChildInSafeZone(
      String childId,
      double centerLat,
      double centerLng,
      double radiusKm,
      ) {
    final currentLoc = _childrenLocations[childId];
    if (currentLoc == null) return false;

    final distance = currentLoc.distanceTo(
      LocationData(
        latitude: centerLat,
        longitude: centerLng,
        accuracy: 0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    return distance <= radiusKm;
  }
  Future<void> stopWatchingChild(String childId) async {
    final sub = _subs[childId];
    if (sub != null) await sub.cancel();

    _subs.remove(childId);
    _childrenLocations.remove(childId);
    _childrenTrails.remove(childId);
    notifyListeners();
  }

  Future<void> stopWatchingAllChildren() async {
    for (final s in _subs.values) {
      await s.cancel();
    }
    _subs.clear();
    _childrenLocations.clear();
    _childrenTrails.clear();

    _status = LocationSharingStatus.paused;
    notifyListeners();
  }

  Future<List<LocationData>> loadLocationHistory(String childId) async {
    try {
      final history = await _repo.getLocationHistory(childId);
      final valid = history.where(_isValidLocation).toList();

      _childrenTrails[childId] = valid;
      if (valid.isNotEmpty) _childrenLocations[childId] = valid.last;

      notifyListeners();
      return valid;
    } catch (e) {
      _setError('Lỗi tải lịch sử: $e');
      return [];
    }
  }

  bool _isValidLocation(LocationData loc) {
    return loc.latitude.isFinite &&
        loc.longitude.isFinite &&
        loc.latitude >= -90 &&
        loc.latitude <= 90 &&
        loc.longitude >= -180 &&
        loc.longitude <= 180;
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = LocationSharingStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }
}
