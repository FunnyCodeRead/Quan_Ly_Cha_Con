import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';

import 'package:quan_ly_cha_con/services/location_service_location_pkg.dart';

// <- đường dẫn tới LocationServiceInterface/Impl của bạn

class ChildLocationViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;
  final LocationServiceInterface _locationService;

  LocationData? currentLocation;
  LocationData? _lastSentLocation; // kiểm tra di chuyển > 100m
  final List<LocationData> locationTrail = [];
  StreamSubscription<LocationData>? _gpsSub;

  bool isSharing = false;

  ChildLocationViewModel(this._locationRepository, this._locationService);

  /// Bắt đầu chia sẻ vị trí tự động (không cho tắt)
  Future<void> startLocationSharing(String childId) async {
    if (isSharing) return;

    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) {
      // không có quyền thì không share được
      isSharing = false;
      notifyListeners();
      return;
    }

    isSharing = true;
    notifyListeners();

    _gpsSub = _locationService.getLocationStream().listen(
          (loc) async {
        currentLocation = loc;

        // Nếu chưa gửi lần nào hoặc di chuyển > 100m (0.1 km)
        if (_lastSentLocation == null ||
            _lastSentLocation!.distanceTo(loc) >= 0.1) {
          await _locationRepository.updateChildLocation(childId, loc);
          _lastSentLocation = loc;
        }

        locationTrail.add(loc);
        notifyListeners();
      },
      onError: (e) {
        // ❗ không cho tắt vĩnh viễn -> tự bật lại
        isSharing = false;
        notifyListeners();

        Future.delayed(const Duration(seconds: 2), () {
          startLocationSharing(childId);
        });
      },
      cancelOnError: false,
    );
  }

  // 🚫 Không cho UI gọi stop nữa
  void _stopInternal() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
    isSharing = false;
    notifyListeners();
  }

  Future<List<LocationData>> loadLocationHistory(String childId) async {
    try {
      final history = await _locationRepository.getLocationHistory(childId);
      locationTrail
        ..clear()
        ..addAll(history);

      if (history.isNotEmpty) currentLocation = history.last;
      notifyListeners();
      return history;
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }
}
