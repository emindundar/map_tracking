import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';

class OpenStreetViewSearch extends StatefulWidget {
  const OpenStreetViewSearch({super.key});

  @override
  State<OpenStreetViewSearch> createState() => _OpenStreetViewSearchState();
}

class _OpenStreetViewSearchState extends State<OpenStreetViewSearch> with TickerProviderStateMixin {

  late final AnimatedMapController _animatedMapController;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _animatedMapController.mapController,
        options: MapOptions(
          initialCenter: const LatLng(37.7827875, 29.0966476),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.emindundar.maptracking',
          ),
        ],
      ),
    );
  }
}