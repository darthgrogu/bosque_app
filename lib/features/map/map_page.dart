import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      // Diretamente o FlutterMap
      options: MapOptions(
        initialCenter: LatLng(-3.0976310, -59.98608),
        initialZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.suaempresa.seujardimbotanico', // CORRETO
        ),
      ],
    );
  }
}
