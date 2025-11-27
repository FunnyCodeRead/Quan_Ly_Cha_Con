import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';

enum LocationSharingStatus { idle, sharing, paused, error }

class ParentLocationViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;

  final Map<String, LocationData> _childrenLocations = {};
  final Map<String, List<LocationData>> _childrenTrails = {};
  final Map<String, StreamSubscription<LocationData>> _subscriptions = {};

  String _errorMessage = '';
  LocationSharingStatus _status = LocationSharingStatus.idle;

  Map<String, LocationData> get childrenLocations => _childrenLocations;
  Map<String, List<LocationData>> get childrenTrails => _childrenTrails;
  String get errorMessage => _errorMessage;
  LocationSharingStatus get status => _status;

  ParentLocationViewModel(this._locationRepository);

  // ========== WATCH SINGLE ==========
  Stream<LocationData> watchChildLocation(String childId) {
    return _locationRepository.watchChildLocation(childId);
  }

  // ========== WATCH MULTI ==========
  Future<void> watchAllChildren(List<String> childIds) async {
    _status = LocationSharingStatus.sharing;
    notifyListeners();

    try {
      for (final childId in childIds) {
        if (_subscriptions.containsKey(childId)) continue;

        _childrenTrails.putIfAbsent(childId, () => []);

        final sub = _locationRepository.watchChildLocation(childId).listen(
              (loc) {
            // ✅ lọc dữ liệu lỗi (NaN/Infinity)
            if (!_isValidLocation(loc)) return;

            _childrenLocations[childId] = loc;

            final trail = _childrenTrails[childId]!;
            // ✅ tránh spam điểm trùng
            if (trail.isEmpty || trail.last.timestamp != loc.timestamp) {
              trail.add(loc);
              // ✅ giới hạn trail để app không nặng
              if (trail.length > 300) {
                trail.removeRange(0, trail.length - 300);
              }
            }

            notifyListeners();
          },
          onError: (e) {
            _setError('Lỗi theo dõi $childId: $e');
          },
        );

        _subscriptions[childId] = sub;
      }
    } catch (e) {
      _setError('Lỗi theo dõi con: $e');
    }
  }

  /// ✅ Gọi khi danh sách con thay đổi (thêm/xoá con)
  Future<void> refreshWatching(List<String> newChildIds) async {
    // stop con không còn trong list
    final oldIds = _subscriptions.keys.toList();
    for (final id in oldIds) {
      if (!newChildIds.contains(id)) {
        await stopWatchingChild(id);
      }
    }

    // watch thêm con mới
    await watchAllChildren(newChildIds);
  }

  // ========== STOP ==========
  Future<void> stopWatchingChild(String childId) async {
    final sub = _subscriptions[childId];
    if (sub != null) {
      await sub.cancel();
    }
    _subscriptions.remove(childId);
    _childrenLocations.remove(childId);
    _childrenTrails.remove(childId);
    notifyListeners();
  }

  Future<void> stopWatchingAllChildren() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _childrenLocations.clear();
    _childrenTrails.clear();

    _status = LocationSharingStatus.paused;
    notifyListeners();
  }

  // ========== HISTORY ==========
  Future<List<LocationData>> loadLocationHistory(String childId) async {
    try {
      final history = await _locationRepository.getLocationHistory(childId);
      final validHistory = history.where(_isValidLocation).toList();

      _childrenTrails[childId] = validHistory;
      if (validHistory.isNotEmpty) {
        _childrenLocations[childId] = validHistory.last;
      }

      notifyListeners();
      return validHistory;
    } catch (e) {
      _setError('Lỗi tải lịch sử: $e');
      return [];
    }
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

  LocationData? getChildLatestLocation(String childId) {
    return _childrenLocations[childId];
  }

  // ========== VALIDATE ==========
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
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
