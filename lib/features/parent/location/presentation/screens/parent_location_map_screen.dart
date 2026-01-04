import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/core/utils/latlng_utils.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';
import 'package:quan_ly_cha_con/features/parent/location/presentation/state/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';





class ParentLocationMapScreen extends StatefulWidget {
  final User child;
  final VoidCallback onBackToAllChildren;

  const ParentLocationMapScreen({
    required this.child,
    required this.onBackToAllChildren,
    Key? key,
  }) : super(key: key);

  @override
  State<ParentLocationMapScreen> createState() => _ParentLocationMapScreenState();
}

class _ParentLocationMapScreenState extends State<ParentLocationMapScreen> {
  final MapController _mapController = MapController();

  LocationData? _currentLocation;

  // route mode
  bool _showRoute = false;
  List<osm.LatLng> _routePoints = [];
  List<Polyline> _routePolylines = [];
  List<Marker> _routeMarkers = [];

  Marker? _currentMarker;

  Future<void> _loadRoute() async {
    final vm = context.read<ParentLocationVm>();
    final history = await vm.loadLocationHistory(widget.child.uid);

    final points = history
        .map((e) => osm.LatLng(e.latitude, e.longitude))
        .where(isValidLatLng)
        .toList();

    if (points.length < 2) return;

    setState(() {
      _showRoute = true;
      _routePoints = points;
      _routePolylines = [
        Polyline(points: points, strokeWidth: 6, color: Colors.blue),
      ];
      _routeMarkers = [
        Marker(
          point: points.first,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.green, size: 36),
        ),
        Marker(
          point: points.last,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
        ),
      ];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  void _clearRoute() {
    setState(() {
      _showRoute = false;
      _routePoints = [];
      _routePolylines = [];
      _routeMarkers = [];
    });
  }

  void _openInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _ChildInfoSheetSingle(
        child: widget.child,
        location: _currentLocation,
        isShowingRoute: _showRoute,
        onToggleSearch: () async {
          Navigator.pop(context);
          if (_showRoute) {
            _clearRoute();
          } else {
            await _loadRoute();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentLocationVm>(
      builder: (context, vm, _) {
        return StreamBuilder<LocationData>(
          stream: vm.watchChildLocation(widget.child.uid),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _currentLocation = snapshot.data;
              final p = osm.LatLng(snapshot.data!.latitude, snapshot.data!.longitude);
              if (isValidLatLng(p)) {
                _currentMarker = Marker(
                  point: p,
                  width: 46,
                  height: 46,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 42),
                );
              }
            }

            final safeCenter = (_currentMarker != null)
                ? _currentMarker!.point
                : const osm.LatLng(21.0285, 105.8542);

            final markers = <Marker>[
              if (_currentMarker != null) _currentMarker!,
              ..._routeMarkers,
            ];

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: safeCenter,
                    initialZoom: 15,
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
                    if (_showRoute && _routePolylines.isNotEmpty)
                      PolylineLayer(polylines: _routePolylines),
                    MarkerLayer(markers: markers),
                  ],
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _SingleChildBottomControls(
                    child: widget.child,
                    onBackToAll: widget.onBackToAllChildren,
                    onMyLocation: () {
                      if (_showRoute && _routePoints.length >= 2) {
                        final bounds = LatLngBounds.fromPoints(_routePoints);
                        _mapController.fitCamera(
                          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                        );
                        return;
                      }
                      if (_currentMarker != null) {
                        _mapController.move(_currentMarker!.point, 17);
                      }
                    },
                    onMore: _openInfoSheet, // ✅ ... mở info + tìm kiếm
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SingleChildBottomControls extends StatelessWidget {
  final User child;
  final VoidCallback onBackToAll;
  final VoidCallback onMyLocation;
  final VoidCallback onMore;

  const _SingleChildBottomControls({
    required this.child,
    required this.onBackToAll,
    required this.onMyLocation,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final name = child.name.isNotEmpty ? child.name : child.email;
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onBackToAll,
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.orange.shade200,
                      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.more_horiz, size: 18),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onMyLocation,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ChildInfoSheetSingle extends StatelessWidget {
  final User child;
  final LocationData? location;
  final bool isShowingRoute;
  final VoidCallback onToggleSearch;

  const _ChildInfoSheetSingle({
    required this.child,
    required this.location,
    required this.isShowingRoute,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    final name = child.name.isNotEmpty ? child.name : child.email;
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Thông tin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.amber.shade200,
                        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(child.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (location != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoTile(label: 'Lat', value: location!.latitude.toStringAsFixed(4)),
                        _InfoTile(label: 'Lng', value: location!.longitude.toStringAsFixed(4)),
                        _InfoTile(label: 'Acc', value: '${location!.accuracy.toStringAsFixed(0)}m'),
                      ],
                    )
                  else
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Đang lấy vị trí...', style: TextStyle(color: Colors.grey)),
                    ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Đóng'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onToggleSearch,
                          icon: Icon(isShowingRoute ? Icons.clear : Icons.search),
                          label: Text(isShowingRoute ? 'Tắt tìm kiếm' : 'Tìm kiếm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
