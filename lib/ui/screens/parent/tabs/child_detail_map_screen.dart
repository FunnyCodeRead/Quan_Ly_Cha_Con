import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/utils/latlng_utils.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';

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
    required this.childId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChildDetailMapScreen> createState() => _ChildDetailMapScreenState();
}

class _ChildDetailMapScreenState extends State<ChildDetailMapScreen> {
  final MapController _mapController = MapController();

  List<LocationData> _history = [];
  List<osm.LatLng> _trail = [];
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<_StopInfo> _stops = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final viewModel = context.read<ParentLocationViewModel>();
    final history = await viewModel.loadLocationHistory(widget.childId);

    _history = history;
    _trail = history
        .map((e) => osm.LatLng(e.latitude, e.longitude))
        .where(isValidLatLng)
        .toList();

    _recomputeStops();

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

  void _handleMapTap(osm.LatLng latlng) {
    if (_trail.isEmpty) return;

    // Chỉ phản hồi khi tap gần đường đi
    final nearestKm = _distanceToTrailKm(latlng);
    if (nearestKm > 0.2) return;

    _showStopsSheet();
  }

  double _distanceToTrailKm(osm.LatLng tap) {
    double minDistance = double.infinity;
    for (final point in _trail) {
      final temp = LocationData(
        latitude: point.latitude,
        longitude: point.longitude,
        accuracy: 0,
        timestamp: 0,
      ).distanceTo(
        LocationData(
          latitude: tap.latitude,
          longitude: tap.longitude,
          accuracy: 0,
          timestamp: 0,
        ),
      );
      if (temp < minDistance) {
        minDistance = temp;
      }
    }
    return minDistance;
  }

  void _buildLayers() {
    _markers = [];
    _polylines = [];

    if (_trail.length > 1) {
      _polylines.add(
        Polyline(
          points: _trail,
          strokeWidth: 5,
          color: Colors.blue,
        ),
      );
    }

    if (_trail.isNotEmpty) {
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

      for (final stop in _stops) {
        _markers.add(
          Marker(
            point: stop.position,
            width: 32,
            height: 32,
            child: const Icon(
              Icons.pause_circle_filled,
              color: Colors.deepPurple,
              size: 28,
            ),
          ),
        );
      }

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
    }

    setState(() {});
  }

  void _recomputeStops() {
    _stops = [];
    if (_history.length < 2) return;

    const double stayThresholdKm = 0.12; // khoảng 120m
    const int minStopMillis = 2 * 60 * 1000; // 2 phút

    int startIndex = 0;

    for (int i = 1; i < _history.length; i++) {
      final prev = _history[i - 1];
      final current = _history[i];
      final movedKm = prev.distanceTo(current);

      if (movedKm <= stayThresholdKm) {
        continue;
      }

      _maybeAddStop(startIndex, i - 1, minStopMillis);
      startIndex = i;
    }

    _maybeAddStop(startIndex, _history.length - 1, minStopMillis);

    _stops.sort(
        (a, b) => b.duration.inMilliseconds.compareTo(a.duration.inMilliseconds));
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParentLocationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử di chuyển của ${widget.childId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              final stats = viewModel.getChildLocationStats(widget.childId);
              _showStats(stats);
            },
          ),
        ],
      ),
      body: StreamBuilder<LocationData>(
        stream: viewModel.watchChildLocation(widget.childId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final loc = snapshot.data!;
            final newPoint = osm.LatLng(
              loc.latitude,
              loc.longitude,
            );

            if (isValidLatLng(newPoint) &&
                (_trail.isEmpty || _trail.last != newPoint)) {
              _history.add(loc);
              _trail.add(newPoint);
              _recomputeStops();
              _buildLayers();
              _mapController.move(newPoint, _mapController.camera.zoom);
            }
          }

          final safeCenter = _trail.isNotEmpty
              ? _trail.last
              : const osm.LatLng(21.0285, 105.8542);

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
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.quan_ly_cha_con',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          );
        },
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
            Text(
              "Quãng đường: ${(stats['totalDistance']).toStringAsFixed(2)} km",
            ),
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
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Điểm dừng nổi bật',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._stops.map(
                (stop) => ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: Text(
                    'Dừng ${(stop.duration.inMinutes)} phút tại (${stop.position.latitude.toStringAsFixed(4)}, ${stop.position.longitude.toStringAsFixed(4)})',
                  ),
                  subtitle: Text(
                    'Từ ${_formatTime(stop.start)} đến ${_formatTime(stop.end)} · ${stop.visitCount} lần ghi nhận',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
  }
}
