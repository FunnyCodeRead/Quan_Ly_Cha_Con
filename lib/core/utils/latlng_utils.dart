import 'package:latlong2/latlong.dart';

bool isValidLatLng(LatLng p) {
  return p.latitude.isFinite &&
      p.longitude.isFinite &&
      p.latitude >= -90 &&
      p.latitude <= 90 &&
      p.longitude >= -180 &&
      p.longitude <= 180;
}
