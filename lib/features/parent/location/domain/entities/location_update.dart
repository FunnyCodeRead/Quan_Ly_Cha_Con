

import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';

class LocationUpdate {
  final String childId;
  final LocationData location;
  final double distanceFromPrevious;
  final DateTime timestamp;

  LocationUpdate({
    required this.childId,
    required this.location,
    required this.distanceFromPrevious,
    required this.timestamp,
  });
}
