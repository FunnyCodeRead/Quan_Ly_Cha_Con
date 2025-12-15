import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/services/location_service_location_pkg.dart';

class ChildLocationViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;
  final LocationServiceInterface _locationService;
  final FirebaseAuth _auth;

  LocationData? currentLocation;
  LocationData? _lastSentLocation;
  final List<LocationData> locationTrail = [];

  StreamSubscription<LocationData>? _gpsSub;
  Timer? _keepAliveTimer;

  String? _currentChildUid;
  bool isSharing = false;

  ChildLocationViewModel(
    this._locationRepository,
    this._locationService, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  String _requireChildUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("Chưa đăng nhập -> không thể chia sẻ vị trí");
    }
    return uid;
  }

  /// ✅ Chỉ dùng khi LOGOUT
  Future<void> stopSharingOnLogout() async {
    await _stopInternal(clearData: true);
  }

  Future<void> _stopInternal({required bool clearData}) async {
    await _gpsSub?.cancel();
    _gpsSub = null;

    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    isSharing = false;

    if (clearData) {
      currentLocation = null;
      _lastSentLocation = null;
      locationTrail.clear();
      _currentChildUid = null;
    }

    notifyListeners();
  }

  /// ✅ Bắt đầu chia sẻ vị trí của CHÍNH user (child) đang login
  Future<void> startLocationSharing() async {
    if (isSharing) return;

    final uid = _requireChildUid();
    _currentChildUid = uid;

    final ok = await _locationService.ensureServiceAndPermission();
    if (!ok) {
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
          await _locationRepository.updateMyLocation(loc); // repo tự lấy uid
          _lastSentLocation = loc;
        }

        locationTrail.add(loc);
        notifyListeners();
      },
      onError: (e, st) async {
        // mất stream/permission -> restart nhẹ
        await _restartSharing(delay: const Duration(seconds: 2));
      },
      cancelOnError: false,
    );

    _startKeepAliveLoop();
  }

  Future<void> _restartSharing({Duration delay = const Duration(seconds: 1)}) async {
    // nếu user đã stop/logout thì khỏi restart
    if (_auth.currentUser?.uid == null) return;

    // cho phép start lại
    await _gpsSub?.cancel();
    _gpsSub = null;

    isSharing = false;
    notifyListeners();

    await Future.delayed(delay);

    // start lại
    await startLocationSharing();
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

  void _startKeepAliveLoop() {
    _keepAliveTimer?.cancel();

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!isSharing) return;

      // kiểm tra quyền/service còn ok không
      final ok = await _locationService.ensureServiceAndPermission();
      if (!ok) {
        await _restartSharing(delay: const Duration(seconds: 1));
        return;
      }

      // nếu subscription bị mất vì lý do nào đó -> tạo lại
      if (_gpsSub == null) {
        await _restartSharing(delay: const Duration(milliseconds: 500));
      }
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _keepAliveTimer?.cancel();
    super.dispose();
  }
}
