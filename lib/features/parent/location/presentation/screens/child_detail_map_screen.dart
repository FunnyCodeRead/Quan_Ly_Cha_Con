// lib/features/parent/location/presentation/pages/child_detail_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/core/utils/latlng_utils.dart';

import '../../domain/entities/location_data.dart';

import '../state/parent_location_view_model.dart';

class _StopInfo {
  final osm.LatLng position;
  final Duration duration;
  final int visitCount;
  final DateTime start;
  final DateTime end;

  _StopInfo({
    required this.position,
    required this.duration,
    required this.visitCount,
    required this.start,
    required this.end,
  });
}

class ChildDetailMapScreen extends StatefulWidget {
  final String childId;

  const ChildDetailMapScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildDetailMapScreen> createState() => _ChildDetailMapScreenState();
}

class _ChildDetailMapScreenState extends State<ChildDetailMapScreen> {
  final MapController _mapController = MapController();

  final List<LocationData> _history = [];
  final List<osm.LatLng> _trail = [];
  final List<_StopInfo> _stops = [];

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  bool _loading = true;
  bool _fittedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    try {
      final vm = context.read<ParentLocationVm>();
      final history = await vm.loadLocationHistory(widget.childId);

      _history
        ..clear()
        ..addAll(history);

      _trail
        ..clear()
        ..addAll(
          history
              .map((e) => osm.LatLng(e.latitude, e.longitude))
              .where(isValidLatLng)
              .toList(),
        );

      _recomputeStops();
      _buildLayers();

      if (!mounted) return;

      // Fit once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitTrailOnce();
      });
    } catch (_) {
      // bạn có thể show snackbar nếu muốn
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fitTrailOnce() {
    if (_fittedOnce) return;
    if (_trail.isEmpty) return;

    _fittedOnce = true;

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
  }

  void _handleMapTap(osm.LatLng latlng) {
    if (_trail.isEmpty) return;

    // chỉ phản hồi khi tap gần trail
    final nearestKm = _distanceToTrailKm(latlng);
    if (nearestKm > 0.2) return; // >200m thì bỏ

    _showStopsSheet();
  }

  double _distanceToTrailKm(osm.LatLng tap) {
    double minDistance = double.infinity;

    // convert tap -> LocationData để dùng distanceTo cho đồng bộ
    final tapLoc = LocationData(
      latitude: tap.latitude,
      longitude: tap.longitude,
      accuracy: 0,
      timestamp: 0,
    );

    for (final p in _trail) {
      final pointLoc = LocationData(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: 0,
        timestamp: 0,
      );

      final d = pointLoc.distanceTo(tapLoc);
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  void _buildLayers() {
    final cs = Theme.of(context).colorScheme;

    _markers = [];
    _polylines = [];

    // line
    if (_trail.length > 1) {
      _polylines.add(
        Polyline(
          points: List<osm.LatLng>.from(_trail),
          strokeWidth: 5,
          color: cs.primary,
        ),
      );
    }

    if (_trail.isNotEmpty) {
      // start
      _markers.add(
        Marker(
          point: _trail.first,
          width: 40,
          height: 40,
          child: Icon(
            Icons.location_pin,
            color: cs.tertiary,
            size: 36,
          ),
        ),
      );

      // stops
      for (final stop in _stops) {
        _markers.add(
          Marker(
            point: stop.position,
            width: 32,
            height: 32,
            child: Icon(
              Icons.pause_circle_filled,
              color: cs.secondary,
              size: 28,
            ),
          ),
        );
      }

      // end
      _markers.add(
        Marker(
          point: _trail.last,
          width: 40,
          height: 40,
          child: Icon(
            Icons.location_pin,
            color: cs.error,
            size: 36,
          ),
        ),
      );
    }

    setState(() {});
  }

  void _recomputeStops() {
    _stops.clear();
    if (_history.length < 2) return;

    const double stayThresholdKm = 0.12; // 120m
    const int minStopMillis = 2 * 60 * 1000; // 2 phút

    int startIndex = 0;

    for (int i = 1; i < _history.length; i++) {
      final prev = _history[i - 1];
      final current = _history[i];
      final movedKm = prev.distanceTo(current);

      // còn ở gần -> coi như vẫn dừng
      if (movedKm <= stayThresholdKm) continue;

      _maybeAddStop(startIndex, i - 1, minStopMillis);
      startIndex = i;
    }

    _maybeAddStop(startIndex, _history.length - 1, minStopMillis);

    // sort stop dài nhất lên đầu
    _stops.sort(
          (a, b) => b.duration.inMilliseconds.compareTo(a.duration.inMilliseconds),
    );
  }

  void _maybeAddStop(int startIdx, int endIdx, int minStopMillis) {
    if (startIdx >= endIdx) return;

    final start = _history[startIdx];
    final end = _history[endIdx];

    final durationMs = end.timestamp - start.timestamp;
    if (durationMs < minStopMillis) return;

    double avgLat = 0;
    double avgLng = 0;

    for (int i = startIdx; i <= endIdx; i++) {
      avgLat += _history[i].latitude;
      avgLng += _history[i].longitude;
    }

    final count = endIdx - startIdx + 1;
    avgLat /= count;
    avgLng /= count;

    _stops.add(
      _StopInfo(
        position: osm.LatLng(avgLat, avgLng),
        duration: Duration(milliseconds: durationMs),
        visitCount: count,
        start: DateTime.fromMillisecondsSinceEpoch(start.timestamp),
        end: DateTime.fromMillisecondsSinceEpoch(end.timestamp),
      ),
    );
  }

  void _showStats(Map<String, dynamic> stats) {
    if (stats.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thống kê hành trình"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Số điểm: ${stats['totalPoints']}"),
            Text("Quãng đường: ${(stats['totalDistance']).toStringAsFixed(2)} km"),
            Text("Thời gian: ${stats['timeSpan']} ms"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  void _showStopsSheet() {
    if (_stops.isEmpty) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true, // ✅ material 3
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Điểm dừng nổi bật',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._stops.map(
                  (stop) => ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: Text(
                  'Dừng ${stop.duration.inMinutes} phút tại '
                      '(${stop.position.latitude.toStringAsFixed(4)}, '
                      '${stop.position.longitude.toStringAsFixed(4)})',
                ),
                subtitle: Text(
                  'Từ ${_formatTime(stop.start)} đến ${_formatTime(stop.end)}'
                      ' · ${stop.visitCount} lần ghi nhận',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ParentLocationVm>();
    final cs = Theme.of(context).colorScheme;

    final safeCenter =
    _trail.isNotEmpty ? _trail.last : const osm.LatLng(21.0285, 105.8542);

    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử di chuyển: ${widget.childId}"),
        actions: [
          IconButton(
            tooltip: "Thống kê",
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              final stats = vm.getChildLocationStats(widget.childId);
              _showStats(stats);
            },
          ),
          IconButton(
            tooltip: "Reload",
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<LocationData>(
            stream: vm.watchChildLocation(widget.childId),
            builder: (context, snapshot) {
              // realtime append
              if (snapshot.hasData) {
                final loc = snapshot.data!;
                final newPoint = osm.LatLng(loc.latitude, loc.longitude);

                if (isValidLatLng(newPoint) &&
                    (_trail.isEmpty || _trail.last != newPoint)) {
                  _history.add(loc);
                  _trail.add(newPoint);
                  _recomputeStops();
                  _buildLayers();

                  // follow camera
                  _mapController.move(newPoint, _mapController.camera.zoom);
                }
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: safeCenter,
                  initialZoom: 16,
                  minZoom: 3,
                  maxZoom: 19,
                  onTap: (_, latlng) => _handleMapTap(latlng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.quan_ly_cha_con',
                  ),
                  if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
                  if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
                ],
              );
            },
          ),

          if (_loading)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                backgroundColor: cs.surfaceVariant,
              ),
            ),
        ],
      ),
      floatingActionButton: _stops.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: _showStopsSheet,
        icon: const Icon(Icons.place_outlined),
        label: const Text("Điểm dừng"),
      ),
    );
  }
}
