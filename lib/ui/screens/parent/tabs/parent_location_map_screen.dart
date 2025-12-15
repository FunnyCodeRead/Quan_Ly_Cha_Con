import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/utils/latlng_utils.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';

class ParentLocationMapScreen extends StatefulWidget {
  final String childId;

  const ParentLocationMapScreen({
    required this.childId,
    Key? key,
  }) : super(key: key);

  @override
  State<ParentLocationMapScreen> createState() =>
      _ParentLocationMapScreenState();
}

class _ParentLocationMapScreenState extends State<ParentLocationMapScreen> {
  final MapController _mapController = MapController();

  List<osm.LatLng> _trail = [];
  LocationData? _currentLocation;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    final viewModel = context.read<ParentLocationViewModel>();
    final history = await viewModel.loadLocationHistory(widget.childId);

    _trail = history
        .map((loc) => osm.LatLng(loc.latitude, loc.longitude))
        .where(isValidLatLng)
        .toList();

    if (history.isNotEmpty) {
      _currentLocation = history.last;
    }

    _buildLayers();

    if (!mounted || _trail.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_trail.length >= 2) {
        final bounds = LatLngBounds.fromPoints(_trail);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      } else {
        _mapController.move(_trail.first, 16);
      }
    });
  }

  void _buildLayers() {
    _markers = [];
    _polylines = [];

    if (_trail.isEmpty) {
      setState(() {});
      return;
    }

    _markers.add(
      Marker(
        point: _trail.first,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_pin,
          color: Colors.green,
          size: 36,
        ),
      ),
    );

    _markers.add(
      Marker(
        point: _trail.last,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 36,
        ),
      ),
    );

    if (_trail.length > 1) {
      _polylines.add(
        Polyline(
          points: _trail,
          strokeWidth: 5,
          color: Colors.blue,
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentLocationViewModel>(
      builder: (context, viewModel, _) {
        return StreamBuilder<LocationData>(
          stream: widget.childId.isNotEmpty
              ? viewModel.watchChildLocation(widget.childId)
              : null,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _currentLocation = snapshot.data;
              final newPoint = osm.LatLng(
                snapshot.data!.latitude,
                snapshot.data!.longitude,
              );

              if (isValidLatLng(newPoint) &&
                  (_trail.isEmpty || _trail.last != newPoint)) {
                _trail.add(newPoint);
                _buildLayers();
                _mapController.move(newPoint, _mapController.camera.zoom);
              }
            }

            final safeCenter = _trail.isNotEmpty
                ? _trail.last
                : const osm.LatLng(21.0285, 105.8542);

            return Column(
              children: [
                _LocationToolbar(),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Stack(
                      children: [
                        if (_trail.isNotEmpty)
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: safeCenter,
                              initialZoom: 15,
                              minZoom: 3,
                              maxZoom: 19,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.quan_ly_cha_con',
                                tileBuilder: (context, widget, tile) =>
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: widget,
                                    ),
                              ),
                              PolylineLayer(polylines: _polylines),
                              MarkerLayer(markers: _markers),
                            ],
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                        const _StatusChips(),
                        _BottomLocationCard(location: _currentLocation),
                      ],
                    ),
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

class _LocationToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _RoundIconButton(
              icon: Icons.arrow_back,
              onPressed: () {
                Navigator.pop(context);
              }),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.black54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RoundIconButton(icon: Icons.notifications_none, onPressed: () {}),
          const SizedBox(width: 8),
          _RoundIconButton(icon: Icons.grid_view, onPressed: () {}),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagChip(
            icon: Icons.emoji_transportation,
            label: 'Đang theo dõi con',
            color: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 8),
          _TagChip(
            icon: Icons.shield_outlined,
            label: 'An toàn',
            color: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _BottomLocationCard extends StatelessWidget {
  final LocationData? location;

  const _BottomLocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.my_location,
                  backgroundColor: Colors.blue,
                  iconColor: Colors.white,
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vị trí hiện tại',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location == null
                            ? 'Đang định vị...'
                            : 'Vị trí đang được chia sẻ liên tục',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
            if (location != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoTile(
                    label: 'Lat',
                    value: location!.latitude.toStringAsFixed(4),
                  ),
                  _InfoTile(
                    label: 'Lng',
                    value: location!.longitude.toStringAsFixed(4),
                  ),
                  _InfoTile(
                    label: 'Độ chính xác',
                    value: '${location!.accuracy.toStringAsFixed(0)} m',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  const _TagChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.black87),
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
