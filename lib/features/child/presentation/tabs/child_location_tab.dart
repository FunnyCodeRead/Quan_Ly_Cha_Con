// lib/features/child/presentation/tabs/child_location_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/features/child/location/presentation/state/child_location_view_model.dart';

import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';

class ChildLocationTab extends StatelessWidget {
  const ChildLocationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChildLocationViewModel>();
    final cs = Theme.of(context).colorScheme;

    final current = vm.currentLocation;
    final trail = vm.locationTrail;

    return Column(
      children: [
        const _LocationToolbar(),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                if (current != null)
                  _LocationMap(
                    center: osm.LatLng(current.latitude, current.longitude),
                    trail: trail,
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                const _StatusChips(),

                _BottomLocationCard(location: current),

                if (vm.isSharing)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _Pill(
                      icon: Icons.wifi_tethering,
                      text: 'Đang chia sẻ',
                      background: cs.primaryContainer,
                      foreground: cs.onPrimaryContainer,
                    ),
                  )
                else
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _Pill(
                      icon: Icons.wifi_off,
                      text: 'Đã dừng',
                      background: cs.surfaceContainerHighest,
                      foreground: cs.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationToolbar extends StatelessWidget {
  const _LocationToolbar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.menu, onPressed: () {}),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () {},
              icon: Icon(Icons.search, color: cs.onSecondaryContainer),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tìm kiếm',
                  style: TextStyle(color: cs.onSecondaryContainer),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
    final cs = Theme.of(context).colorScheme;

    final points = trail
        .map((e) => osm.LatLng(e.latitude, e.longitude))
        .toList(growable: false);

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
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.quan_ly_cha_con',
        ),

        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 4,
                color: cs.primary,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            Marker(
              width: 48,
              height: 48,
              point: center,
              child: Icon(
                Icons.location_on,
                size: 42,
                color: cs.error,
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
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(
            icon: Icons.emoji_transportation,
            text: 'Note: trạng thái demo',
            background: cs.surfaceContainerHighest,
            foreground: cs.onSurface,
          ),
          const SizedBox(height: 8),
          _Pill(
            icon: Icons.home_filled,
            text: 'Đang ở đâu đó',
            background: cs.tertiaryContainer,
            foreground: cs.onTertiaryContainer,
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
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.my_location,
                    backgroundColor: cs.primary,
                    iconColor: cs.onPrimary,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí hiện tại',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location == null
                              ? 'Đang định vị...'
                              : 'Vị trí đang được chia sẻ liên tục',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
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
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w600, color: foreground),
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
    final cs = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? cs.surfaceContainerHighest,
        foregroundColor: iconColor ?? cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
