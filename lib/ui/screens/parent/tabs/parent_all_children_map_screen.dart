import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/models/user.dart';
import 'package:quan_ly_cha_con/utils/latlng_utils.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';

class ParentAllChildrenMapScreen extends StatefulWidget {
  final List<User> children;
  final String? focusChildId; // nếu chọn 1 con -> focus

  const ParentAllChildrenMapScreen({
    required this.children,
    this.focusChildId,
    Key? key,
  }) : super(key: key);

  @override
  State<ParentAllChildrenMapScreen> createState() =>
      _ParentAllChildrenMapScreenState();
}

class _ParentAllChildrenMapScreenState
    extends State<ParentAllChildrenMapScreen> {
  final MapController _mapController = MapController();
  bool _fittedOnce = false;

  @override
  void initState() {
    super.initState();

    // đảm bảo watchAllChildren được gọi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ParentLocationViewModel>();
      final ids = widget.children.map((e) => e.uid).toList();
      vm.watchAllChildren(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentLocationViewModel>(
      builder: (context, vm, _) {
        final trailsMap = vm.childrenTrails;
        final latestMap = vm.childrenLocations;

        // ====== POLYLINES (mỗi con 1 đường đi) ======
        final polylines = <Polyline>[];

        for (final entry in trailsMap.entries) {
          final line = _buildPolylineForChild(entry.key, entry.value);
          if (line != null) polylines.add(line);
        }


        // ====== MARKERS (mỗi con 1 pin + label) ======
        final markers = <Marker>[];
        for (final child in widget.children) {
          final latest = latestMap[child.uid];
          if (latest == null) continue;

          final p = osm.LatLng(latest.latitude, latest.longitude);
          if (!isValidLatLng(p)) continue;

          markers.add(
            Marker(
              key: ValueKey(child.uid), // để focus theo id
              point: p,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showChildInfo(child, latest),
                child: Column(
                  children: [
                    // label tên con
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(blurRadius: 2, color: Colors.black26)
                        ],
                      ),
                      child: Text(
                        child.name.isNotEmpty ? child.name : child.email,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ====== CAMERA LOGIC ======
        _handleCamera(markers);

        // center fallback
        final safeCenter = markers.isNotEmpty
            ? markers.first.point
            : const osm.LatLng(21.0285, 105.8542);

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: safeCenter,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.quan_ly_cha_con',
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  // ---- helpers ----

  Polyline? _buildPolylineForChild(
      String childId, List<LocationData> trailData) {
    final points = trailData
        .map((e) => osm.LatLng(e.latitude, e.longitude))
        .where(isValidLatLng)
        .toList();

    if (points.length < 2) return null;

    // màu theo index để phân biệt
    final idx = widget.children.indexWhere((c) => c.uid == childId);
    final color = Colors.primaries[
    (idx < 0 ? 0 : idx) % Colors.primaries.length];

    return Polyline(
      points: points,
      strokeWidth: 5,
      color: color,
    );
  }

  void _handleCamera(List<Marker> markers) {
    if (markers.isEmpty) return;

    final focusId = widget.focusChildId;

    // focus con được chọn
    if (focusId != null) {
      final focusMarker = markers.firstWhere(
            (m) => m.key == ValueKey(focusId),
        orElse: () => markers.first,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(focusMarker.point, 17);
      });

      return;
    }

    // fit all lần đầu
    if (!_fittedOnce) {
      _fittedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final points = markers.map((m) => m.point).toList();
        if (points.length >= 2) {
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
          );
        } else {
          _mapController.move(points.first, 15);
        }
      });
    }
  }

  void _showChildInfo(User child, LocationData latest) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👶 ${child.name.isNotEmpty ? child.name : child.email}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Lat: ${latest.latitude.toStringAsFixed(6)}"),
            Text("Lng: ${latest.longitude.toStringAsFixed(6)}"),
            Text("Accuracy: ${latest.accuracy.toStringAsFixed(1)} m"),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
