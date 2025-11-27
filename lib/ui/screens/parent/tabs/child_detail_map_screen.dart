import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/utils/latlng_utils.dart';

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

  List<osm.LatLng> _trail = [];
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final viewModel = context.read<ParentLocationViewModel>();
    final history = await viewModel.loadLocationHistory(widget.childId);

    _trail = history
        .map((e) => osm.LatLng(e.latitude, e.longitude))
        .where(isValidLatLng)
        .toList();

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

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: safeCenter,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 19,
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
}
