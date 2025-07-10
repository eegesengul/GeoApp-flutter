import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harita')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(41.0082, 28.9784),
          initialZoom: 13,
          onTap: (tapPosition, point) {
            setState(() {
              markers.add(
                Marker(
                  width: 40,
                  height: 40,
                  point: point,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              );
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.geoapp_flutter', // Bunu kendi package adınla değiştir!
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
