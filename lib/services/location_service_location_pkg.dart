import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:quan_ly_cha_con/models/location_data.dart';

abstract class LocationServiceInterface {
  /// Bảo đảm GPS bật + quyền foreground/background đầy đủ
  Future<bool> ensureServiceAndPermission();

  /// Stream vị trí liên tục
  Stream<LocationData> getLocationStream();
}

class LocationServiceImpl implements LocationServiceInterface {
  final loc.Location _location = loc.Location();

  @override
  Future<bool> ensureServiceAndPermission() async {
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
      if (permission != loc.PermissionStatus.granted &&
          permission != loc.PermissionStatus.grantedLimited) {
        return false;
      }
    }

    // 3) xin quyền background (Android/iOS)
    final bgOk = await _location.enableBackgroundMode(enable: true);
    if (!bgOk) {
      // user chưa cấp Always
      return false;
    }

    // 4) setting để tiết kiệm pin + chỉ gửi khi di chuyển >=100m
    await _location.changeSettings(
      accuracy: loc.LocationAccuracy.low,
      distanceFilter: 100,
      interval: 60000, // Android ms
    );

    // 5) foreground notification (Android)
    await _location.changeNotificationOptions(
      title: "Đang chia sẻ vị trí",
      subtitle: "Ứng dụng chạy nền để bảo vệ con",
      onTapBringToFront: true,
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
