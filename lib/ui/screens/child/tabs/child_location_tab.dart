import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as osm;

import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/viewmodel/children/child_location_view_model.dart';

class ChildLocationTab extends StatelessWidget {
  const ChildLocationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildLocationViewModel>();
    final current = viewModel.currentLocation;

    return Column(
      children: [
        _LocationToolbar(),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                if (current != null)
                  _LocationMap(
                    center: current.latLng,
                    trail: viewModel.locationTrail,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                const _StatusChips(),
                _BottomLocationCard(location: current),
              ],
            ),
          ),
        ),
      ],
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
          _RoundIconButton(icon: Icons.menu, onPressed: () {}),
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

class _LocationMap extends StatelessWidget {
  final osm.LatLng center;
  final List<LocationData> trail;

  const _LocationMap({required this.center, required this.trail});

  @override
  Widget build(BuildContext context) {
    final polylinePoints = trail.map((e) => e.latLng).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          tileBuilder: (context, widget, tile) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget,
          ),
        ),
        if (polylinePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4,
                color: Colors.blueAccent,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              width: 48,
              height: 48,
              point: center,
              child: const Icon(
                Icons.location_on,
                size: 42,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
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
            label: 'Đang tới trường',
            color: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 8),
          _TagChip(
            icon: Icons.home_filled,
            label: 'Dừng nhà',
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
                        _buildSubtitle(),
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
                  _InfoTile(label: 'Lat', value: location!.latitude.toStringAsFixed(4)),
                  _InfoTile(label: 'Lng', value: location!.longitude.toStringAsFixed(4)),
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

  String _buildSubtitle() {
    if (location == null) return 'Đang định vị...';
    return 'Vị trí đang được chia sẻ liên tục';
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
