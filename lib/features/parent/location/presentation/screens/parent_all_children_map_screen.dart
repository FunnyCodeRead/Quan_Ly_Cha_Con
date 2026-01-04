import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/features/chat/presentation/pages/chat_screen.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';
import 'package:quan_ly_cha_con/features/parent/location/presentation/state/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart' show User;


import '../state/parent_all_children_map_controller.dart';
import '../widgets/child_info_sheet.dart';
import '../widgets/children_picker_sheet.dart';
import '../widgets/map_bottom_controls.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/map_top_bar.dart';



bool isValidLatLng(osm.LatLng p) =>
    p.latitude.isFinite &&
        p.longitude.isFinite &&
        p.latitude >= -90 &&
        p.latitude <= 90 &&
        p.longitude >= -180 &&
        p.longitude <= 180;

class ParentAllChildrenMapScreen extends StatelessWidget {
  final List<User> children;

  const ParentAllChildrenMapScreen({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentAllChildrenMapController(),
      child: _ParentAllChildrenMapView(children: children),
    );
  }
}

class _ParentAllChildrenMapView extends StatefulWidget {
  final List<User> children;

  const _ParentAllChildrenMapView({required this.children});

  @override
  State<_ParentAllChildrenMapView> createState() => _ParentAllChildrenMapViewState();
}

class _ParentAllChildrenMapViewState extends State<_ParentAllChildrenMapView> {
  final MapController _mapController = MapController();
  bool _fittedOnce = false;

  final TextEditingController _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _fitAllOnce(List<Marker> markers) {
    if (_fittedOnce || markers.isEmpty) return;
    _fittedOnce = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pts = markers.map((m) => m.point).toList();
      if (pts.length >= 2) {
        final b = LatLngBounds.fromPoints(pts);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(60)),
        );
      } else {
        _mapController.move(pts.first, 15);
      }
    });
  }

  void _fitRouteOrAll({
    required List<Marker> markers,
    required List<osm.LatLng> routePoints,
  }) {
    if (routePoints.length >= 2) {
      final b = LatLngBounds.fromPoints(routePoints);
      _mapController.fitCamera(CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(60)));
      return;
    }

    if (markers.isEmpty) return;
    final pts = markers.map((m) => m.point).toList();
    if (pts.length >= 2) {
      final b = LatLngBounds.fromPoints(pts);
      _mapController.fitCamera(CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(60)));
    } else {
      _mapController.move(pts.first, 15);
    }
  }

  void _openInfoSheet({
    required User child,
    required LocationData latest,
    required bool isSearching,
  }) {
    final controller = context.read<ParentAllChildrenMapController>();
    final locationVM = context.read<ParentLocationVm>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => ChildInfoSheet(
        child: child,
        latest: latest,
        isSearching: isSearching,

        // ✅ bấm icon chat -> đóng sheet -> mở chat
        onOpenChat: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(child: child)),
          );
        },

        // ✅ quick message: tạm để bạn nối repo chat sau
        onSendQuickMessage: (message) async {
          // TODO: nối ChatRepository/ChatViewModel sau
          // hiện tại demo: chỉ đóng sheet
          // await Future.delayed(const Duration(milliseconds: 200));
        },

        onToggleSearch: () async {
          Navigator.pop(context);
          final pts = await controller.toggleRoute(locationVM: locationVM, child: child);
          if (pts.length >= 2) {
            final b = LatLngBounds.fromPoints(pts);
            _mapController.fitCamera(CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(60)));
          }
        },
      ),
    );
  }

  void _openChildrenPicker(Map<String, LocationData> latestMap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => ChildrenPickerSheet(
        children: widget.children,
        latestMap: latestMap,
        onPick: (child, latest) {
          Navigator.pop(context);

          final p = osm.LatLng(latest.latitude, latest.longitude);
          if (!isValidLatLng(p)) return;

          _mapController.move(p, 17);

          final controller = context.read<ParentAllChildrenMapController>();
          _openInfoSheet(
            child: child,
            latest: latest,
            isSearching: controller.isRouteActiveFor(child.uid),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationVM = context.watch<ParentLocationVm>(); // ✅ vm mới
    final controller = context.watch<ParentAllChildrenMapController>();
    final latestMap = locationVM.childrenLocations; // ✅ Map<String, LocationData>

    final markers = <Marker>[];
    for (final child in widget.children) {
      final latest = latestMap[child.uid];
      if (latest == null) continue;

      final p = osm.LatLng(latest.latitude, latest.longitude);
      if (!isValidLatLng(p)) continue;

      final name = child.name.isNotEmpty ? child.name : child.email;

      markers.add(
        Marker(
          key: ValueKey(child.uid),
          point: p,
          width: 90,
          height: 90,
          child: GestureDetector(
            onTap: () => _openInfoSheet(
              child: child,
              latest: latest,
              isSearching: controller.isRouteActiveFor(child.uid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.location_pin, color: Colors.red, size: 44),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.routePoints.isEmpty) _fitAllOnce(markers);

    final safeCenter = markers.isNotEmpty ? markers.first.point : const osm.LatLng(21.0285, 105.8542);

    // route layer
    final routeMarkers = <Marker>[];
    if (controller.routePoints.length >= 2) {
      routeMarkers.addAll([
        Marker(
          point: controller.routePoints.first,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.green, size: 36),
        ),
        Marker(
          point: controller.routePoints.last,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
        ),
      ]);
    }

    final routePolylines = controller.routePoints.length >= 2
        ? [Polyline(points: controller.routePoints, strokeWidth: 6, color: Colors.blue)]
        : <Polyline>[];

    final topInset = MediaQuery.paddingOf(context).top;
    final searchTop = topInset + 52 + 10;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: safeCenter,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.quan_ly_cha_con',
            ),
            if (routePolylines.isNotEmpty) PolylineLayer(polylines: routePolylines),
            MarkerLayer(markers: [...markers, ...routeMarkers]),
          ],
        ),

        MapTopBar(onMenuTap: () {}, onAvatarTap: () {}),

        MapSearchBar(
          controller: _searchCtl,
          topOffset: searchTop,
          onSubmitted: (_) {},
          onFilterTap: () {},
        ),

        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: MapBottomControls(
              children: widget.children,
              onTapChild: (child) {
                final latest = latestMap[child.uid];
                if (latest == null) return;

                final p = osm.LatLng(latest.latitude, latest.longitude);
                if (!isValidLatLng(p)) return;

                _mapController.move(p, 17);
                _openInfoSheet(
                  child: child,
                  latest: latest,
                  isSearching: controller.isRouteActiveFor(child.uid),
                );
              },
              onMore: () => _openChildrenPicker(latestMap),
              onMyLocation: () => _fitRouteOrAll(markers: markers, routePoints: controller.routePoints),
            ),
          ),
        ),
      ],
    );
  }
}
