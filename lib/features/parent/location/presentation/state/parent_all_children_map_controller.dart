import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:quan_ly_cha_con/features/parent/location/presentation/state/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';



class ParentAllChildrenMapController extends ChangeNotifier {
  String? _activeRouteChildId;
  List<osm.LatLng> _routePoints = [];

  List<osm.LatLng> get routePoints => _routePoints;

  bool isRouteActiveFor(String childId) => _activeRouteChildId == childId && _routePoints.length >= 2;

  Future<List<osm.LatLng>> toggleRoute({
    required ParentLocationVm locationVM,
    required User child,
  }) async {
    // nếu đang bật cho đúng child -> tắt
    if (_activeRouteChildId == child.uid && _routePoints.isNotEmpty) {
      _activeRouteChildId = null;
      _routePoints = [];
      notifyListeners();
      return _routePoints;
    }

    // bật route cho child mới
    final history = await locationVM.loadLocationHistory(child.uid);
    final points = history
        .map((e) => osm.LatLng(e.latitude, e.longitude))
        .toList();

    if (points.length < 2) {
      _activeRouteChildId = null;
      _routePoints = [];
      notifyListeners();
      return _routePoints;
    }

    _activeRouteChildId = child.uid;
    _routePoints = points;
    notifyListeners();
    return _routePoints;
  }

  void clearRoute() {
    _activeRouteChildId = null;
    _routePoints = [];
    notifyListeners();
  }
}
