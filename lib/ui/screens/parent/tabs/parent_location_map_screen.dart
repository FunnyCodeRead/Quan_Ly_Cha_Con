import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/utils/latlng_utils.dart';

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

    // Start marker
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

    // Current marker
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

    // Polyline
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
                initialZoom: 15,
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
        );
      },
    );
  }
}
