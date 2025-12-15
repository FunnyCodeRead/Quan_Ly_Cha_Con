import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/services/location_service_location_pkg.dart';

class ChildLocationViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;
  final LocationServiceInterface _locationService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LocationData? currentLocation;
  LocationData? _lastSentLocation;
  final List<LocationData> locationTrail = [];

  StreamSubscription<LocationData>? _gpsSub;
  Timer? _keepAliveTimer;

  bool isSharing = false;

  ChildLocationViewModel(this._locationRepository, this._locationService);

  String _requireChildUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("Chưa đăng nhập -> không thể chia sẻ vị trí");
    }
    return uid;
  }

  /// ✅ Chỉ dùng khi LOGOUT
  Future<void> stopSharingOnLogout() async {
    await _gpsSub?.cancel();
    _gpsSub = null;

    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    isSharing = false;
    currentLocation = null;
    locationTrail.clear();
    _lastSentLocation = null;

    notifyListeners();
  }

  /// ✅ Bắt đầu chia sẻ vị trí của CHÍNH CON đang login
  Future<void> startLocationSharing() async {
    if (isSharing) return;

    _requireChildUid(); // chỉ để chắc chắn đang login

    final hasPermission = await _locationService.ensureServiceAndPermission();
    if (!hasPermission) {
      isSharing = false;
      notifyListeners();
      return;
    }

    isSharing = true;
    notifyListeners();

    _gpsSub = _locationService.getLocationStream().listen(
          (loc) async {
        currentLocation = loc;

        // Nếu chưa gửi lần nào hoặc di chuyển > 100m
        if (_lastSentLocation == null ||
            _lastSentLocation!.distanceTo(loc) >= 0.1) {
          await _locationRepository.updateMyLocation(loc); // ✅ repo tự lấy uid
          _lastSentLocation = loc;
        }

        locationTrail.add(loc);
        notifyListeners();
      },
      onError: (e) {
        isSharing = false;
        notifyListeners();

        Future.delayed(const Duration(seconds: 2), () {
          startLocationSharing();
        });
      },
      cancelOnError: false,
    );

    _startKeepAliveLoop();
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
    _keepAliveTimer?.cancel();
    super.dispose();
  }

  void _startKeepAliveLoop() {
    _keepAliveTimer?.cancel();

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final ok = await _locationService.ensureServiceAndPermission();
      if (!ok) {
        isSharing = false;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        startLocationSharing();
        return;
      }

      if (_gpsSub == null) {
        startLocationSharing();
      }
    });
  }
}
