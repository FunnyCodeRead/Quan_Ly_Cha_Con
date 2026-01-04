import 'dart:async';
import 'package:location/location.dart' as loc;

import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';

abstract class LocationServiceInterface {
  /// Bảo đảm GPS bật + quyền foreground/background (tuỳ requireBackground)
  Future<bool> ensureServiceAndPermission({required bool requireBackground});

  /// Stream vị trí liên tục
  Stream<LocationData> getLocationStream();
}

class LocationServiceImpl implements LocationServiceInterface {
  final loc.Location _location = loc.Location();

  @override
  Future<bool> ensureServiceAndPermission({required bool requireBackground}) async {
    // 1) bật GPS service
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    // 2) xin quyền foreground
    var permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    final fgGranted =
        permission == loc.PermissionStatus.granted ||
            permission == loc.PermissionStatus.grantedLimited;

    if (!fgGranted) return false;

    // 3) background (chỉ khi cần)
    if (requireBackground) {
      final bgOk = await _location.enableBackgroundMode(enable: true);
      if (!bgOk) {
        // user chưa cấp Always / hoặc chưa bật trong Settings
        return false;
      }

      // 5) foreground notification (Android - khi background mode bật)
      await _location.changeNotificationOptions(
        title: "Đang chia sẻ vị trí",
        subtitle: "Ứng dụng chạy nền để bảo vệ con",
        onTapBringToFront: true,
      );
    } else {
      // nếu không cần background thì tắt background mode để đỡ tốn pin
      await _location.enableBackgroundMode(enable: false);
    }

    // 4) setting để tiết kiệm pin + chỉ gửi khi di chuyển >=100m
    await _location.changeSettings(
      accuracy: loc.LocationAccuracy.low,
      distanceFilter: 100,
      interval: 60000, // Android ms
    );

    return true;
  }

  @override
  Stream<LocationData> getLocationStream() {
    return _location.onLocationChanged.map((loc.LocationData l) {
      return LocationData(
        latitude: l.latitude ?? 0,
        longitude: l.longitude ?? 0,
        accuracy: (l.accuracy ?? 0).toDouble(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }
}
