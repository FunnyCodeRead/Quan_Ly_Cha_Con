import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:quan_ly_cha_con/models/location_data.dart';

abstract class LocationServiceInterface {
  /// Bảo đảm dịch vụ vị trí & quyền luôn được bật (kể cả khi quay lại từ nền).
  Future<bool> ensureServiceAndPermission();
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
      if (permission != loc.PermissionStatus.granted) return false;
    }

    // 3) bật background mode -> Android tự show foreground notification
    final bgOk = await _location.enableBackgroundMode(enable: true);
    if (!bgOk) {
      // iOS/Android có thể từ chối background nếu user chưa cấp “Always”
      return false;
    }

    // 4) cấu hình tần suất & độ chính xác
    await _location.changeSettings(
      // Độ chính xác thấp hơn để tiết kiệm pin, đồng thời lọc bước di chuyển nhỏ
      accuracy: loc.LocationAccuracy.low,
      distanceFilter: 100, // mét
      interval: 60000, // ms Android
    );

    // (Tuỳ chọn) tuỳ biến foreground notification Android
    await _location.changeNotificationOptions(
      title: "Đang chia sẻ vị trí",
      subtitle: "Ứng dụng chạy nền để bảo vệ con",
      onTapBringToFront: true,
    ); // chỉ Android, iOS bỏ qua

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
