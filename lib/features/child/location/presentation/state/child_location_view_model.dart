// lib/features/child/location/presentation/state/child_location_view_model.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quan_ly_cha_con/core/services/location/location_service.dart';

import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/repositories/location_repository.dart';

class ChildLocationViewModel extends ChangeNotifier {
  ChildLocationViewModel(
      this._locationRepository,
      this._locationService, {
        FirebaseAuth? auth,
      }) : _auth = auth ?? FirebaseAuth.instance;

  final LocationRepository _locationRepository;
  final LocationServiceInterface _locationService;
  final FirebaseAuth _auth;

  // ===== STATE =====
  LocationData? _currentLocation;
  LocationData? get currentLocation => _currentLocation;

  final List<LocationData> _trail = [];
  List<LocationData> get locationTrail => List.unmodifiable(_trail);

  bool _isSharing = false;
  bool get isSharing => _isSharing;

  bool _requireBackground = false;
  bool get requireBackground => _requireBackground;

  String? _error;
  String? get error => _error;

  // ===== INTERNAL =====
  LocationData? _lastSentLocation;
  StreamSubscription<LocationData>? _gpsSub;
  Timer? _keepAliveTimer;

  bool _restarting = false;

  static const double _minSendDistanceKm = 0.1; // 100m
  static const Duration _keepAliveEvery = Duration(seconds: 30);

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("Chưa đăng nhập -> không thể chia sẻ vị trí");
    }
    return uid;
  }

  void _setError(Object? e) {
    _error = e?.toString();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ dùng khi LOGOUT (clear sạch state)
  Future<void> stopSharingOnLogout() async {
    await stopSharing(clearData: true);
  }

  /// Stop sharing (clearData=false nếu chỉ muốn tạm dừng, true nếu logout)
  Future<void> stopSharing({bool clearData = false}) async {
    await _gpsSub?.cancel();
    _gpsSub = null;

    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    _isSharing = false;
    _restarting = false;

    if (clearData) {
      _currentLocation = null;
      _lastSentLocation = null;
      _trail.clear();
      _requireBackground = false;
      _error = null;
    }

    notifyListeners();
  }

  /// ✅ Start sharing (mặc định foreground để chắc chắn hiện permission popup)
  Future<void> startLocationSharing({bool background = false}) async {
    if (_isSharing) return;

    try {
      _requireUid(); // validate
    } catch (e) {
      _setError(e);
      return;
    }

    _error = null;

    // allow caller override requireBackground
    _requireBackground = background;
    notifyListeners();

    final ok = await _locationService.ensureServiceAndPermission(
      requireBackground: _requireBackground,
    );

    if (!ok) {
      _isSharing = false;
      notifyListeners();
      return;
    }

    _isSharing = true;
    notifyListeners();

    // listen GPS stream
    _gpsSub = _locationService.getLocationStream().listen(
          (loc) async {
        _currentLocation = loc;

        // gửi nếu chưa gửi lần nào hoặc di chuyển > 100m
        if (_lastSentLocation == null ||
            _lastSentLocation!.distanceTo(loc) >= _minSendDistanceKm) {
          try {
            await _locationRepository.updateMyLocation(loc); // repo tự lấy uid
            _lastSentLocation = loc;
          } catch (e) {
            _setError(e);
          }
        }

        _trail.add(loc);
        notifyListeners();
      },
      onError: (e, __) async {
        _setError(e);
        await _restartSharing(delay: const Duration(seconds: 2));
      },
      cancelOnError: false,
    );

    _startKeepAliveLoop();
  }

  /// ✅ Android 11+: bật background permission (thường sẽ mở Settings)
  Future<void> enableBackgroundSharing() async {
    _requireBackground = true;
    notifyListeners();

    final ok = await _locationService.ensureServiceAndPermission(
      requireBackground: true,
    );

    if (!ok) return;

    // Nếu đã share rồi thì restart 1 lần để chắc stream chạy theo permission mới
    if (_isSharing) {
      await _restartSharing(delay: const Duration(milliseconds: 300));
    }
  }

  Future<void> _restartSharing({Duration delay = const Duration(seconds: 1)}) async {
    if (_restarting) return;
    _restarting = true;

    // nếu user logout giữa chừng
    if (_auth.currentUser?.uid == null) {
      _restarting = false;
      return;
    }

    try {
      await _gpsSub?.cancel();
      _gpsSub = null;

      _isSharing = false;
      notifyListeners();

      await Future.delayed(delay);

      // start lại với mode hiện tại
      await startLocationSharing(background: _requireBackground);
    } finally {
      _restarting = false;
    }
  }

  /// Load lịch sử (dùng chung cho tab History)
  Future<List<LocationData>> loadLocationHistory(String childId) async {
    try {
      final history = await _locationRepository.getLocationHistory(childId);

      _trail
        ..clear()
        ..addAll(history);

      if (history.isNotEmpty) {
        _currentLocation = history.last;
      }

      notifyListeners();
      return history;
    } catch (e) {
      _setError(e);
      return [];
    }
  }

  void _startKeepAliveLoop() {
    _keepAliveTimer?.cancel();

    _keepAliveTimer = Timer.periodic(_keepAliveEvery, (_) async {
      if (!_isSharing) return;

      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: _requireBackground,
      );

      if (!ok) {
        await _restartSharing(delay: const Duration(seconds: 1));
        return;
      }

      // stream chết thì restart
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
