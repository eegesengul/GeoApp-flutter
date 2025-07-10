import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart'; // DİKKAT: Doğru import!
import '../models/point_model.dart';
import '../models/area_model.dart';
import '../services/api_service.dart';

enum MapMode { marker, polygon }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapMode currentMode = MapMode.marker;

  List<PointModel> geoPoints = [];
  List<AreaModel> geoAreas = [];

  LatLng? tempMarkerPoint;
  List<LatLng> tempPolygonPoints = [];
  LatLng? liveLinePoint;

  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    fetchPoints();
    fetchAreas();
  }

  Future<void> fetchPoints() async {
    final response = await ApiService.get('points');
    if (response.statusCode == 200) {
      final geojson = jsonDecode(response.body);
      setState(() {
        geoPoints = (geojson['features'] as List)
            .map((f) => PointModel.fromGeoJson(f))
            .toList();
      });
    }
  }

  Future<void> fetchAreas() async {
    final response = await ApiService.get('areas');
    if (response.statusCode == 200) {
      final geojson = jsonDecode(response.body);
      setState(() {
        geoAreas = (geojson['features'] as List)
            .map((f) => AreaModel.fromGeoJson(f))
            .toList();
      });
    }
  }

  void _toggleMode() {
    setState(() {
      if (currentMode == MapMode.marker) {
        currentMode = MapMode.polygon;
        tempMarkerPoint = null;
      } else {
        currentMode = MapMode.marker;
        tempPolygonPoints.clear();
        liveLinePoint = null;
      }
    });
  }

  void _addTempMarker(LatLng point) {
    setState(() {
      tempMarkerPoint = point;
    });
  }

  void _addPolygonPoint(LatLng point) {
    setState(() {
      tempPolygonPoints.add(point);
      liveLinePoint = null;
    });
  }

  void _cancelMarker() {
    setState(() {
      tempMarkerPoint = null;
    });
  }

  void _cancelPolygon() {
    setState(() {
      tempPolygonPoints.clear();
      liveLinePoint = null;
    });
  }

  void _undoPolygonPoint() {
    setState(() {
      if (tempPolygonPoints.isNotEmpty) {
        tempPolygonPoints.removeLast();
      }
      liveLinePoint = null;
    });
  }

  Future<void> _saveMarker(BuildContext context) async {
    if (tempMarkerPoint == null) return;
    final result = await _showNameDescDialog(context, "Nokta");
    if (result == null) return;

    final geoJson = {
      "type": "Point",
      "coordinates": [tempMarkerPoint!.longitude, tempMarkerPoint!.latitude]
    };

    final body = {
      "name": result['name'],
      "description": result['desc'],
      "geoJsonGeometry": jsonEncode(geoJson),
    };
    final response = await ApiService.post('points', body);
    if (!context.mounted) return;
    if (response.statusCode == 201) {
      await fetchPoints();
      setState(() {
        tempMarkerPoint = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Nokta kaydedilemedi! Hata kodu: ${response.statusCode}")),
      );
    }
  }

  Future<void> _savePolygon(BuildContext context) async {
    if (tempPolygonPoints.length < 3) return;
    final result = await _showNameDescDialog(context, "Alan");
    if (result == null) return;
    List<List<double>> coords =
        tempPolygonPoints.map((p) => [p.longitude, p.latitude]).toList();
    if (coords.first[0] != coords.last[0] ||
        coords.first[1] != coords.last[1]) {
      coords.add(coords.first);
    }
    final geoJson = {
      "type": "Polygon",
      "coordinates": [coords]
    };
    final body = {
      "name": result['name'],
      "description": result['desc'],
      "geoJsonGeometry": jsonEncode(geoJson),
    };
    final response = await ApiService.post('areas', body);
    if (!context.mounted) return;
    if (response.statusCode == 201) {
      await fetchAreas();
      setState(() {
        tempPolygonPoints.clear();
        liveLinePoint = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Alan kaydedilemedi! Hata kodu: ${response.statusCode}")),
      );
    }
  }

  Future<Map<String, String>?> _showNameDescDialog(
      BuildContext context, String type) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'İsim'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.of(context).pop({
                'name': nameController.text.trim(),
                'desc': descController.text.trim()
              });
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _showMarkerInfo(BuildContext context, String name, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(desc.isNotEmpty ? desc : "(Açıklama yok)"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _showPolygonInfo(BuildContext context, String name, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(desc.isNotEmpty ? desc : "(Açıklama yok)"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    for (final poly in geoAreas) {
      if (_pointInPolygon(latlng, poly.points)) {
        _showPolygonInfo(context, poly.name, poly.description);
        return;
      }
    }
    for (final marker in geoPoints) {
      final distance = Distance().as(LengthUnit.Meter, marker.latLng, latlng);
      if (distance < 20) {
        _showMarkerInfo(context, marker.name, marker.description);
        return;
      }
    }
    if (currentMode == MapMode.marker) {
      _addTempMarker(latlng);
    } else if (currentMode == MapMode.polygon) {
      _addPolygonPoint(latlng);
    }
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (var j = 0; j < polygon.length; j++) {
      var i = (j + 1) % polygon.length;
      if (_rayCastIntersect(point, polygon[j], polygon[i])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false;
    }
    double m = (bY - aY) / (bX - aX);
    double bee = -aX * m + aY;
    double x = (pY - bee) / m;
    return x > pX;
  }

  Color colorWithOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harita')),
      body: Listener(
        onPointerMove: (event) {
          if (currentMode == MapMode.polygon && tempPolygonPoints.isNotEmpty) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localOffset = box.globalToLocal(event.position);
            final latlng = mapController.camera
                .pointToLatLng(Point(localOffset.dx, localOffset.dy));
            setState(() {
              liveLinePoint = latlng;
            });
          }
        },
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(41.0082, 28.9784),
                initialZoom: 13,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.geoapp_flutter',
                ),
                PolygonLayer(
                  polygons: [
                    ...geoAreas.map((poly) => Polygon(
                          points: poly.points,
                          color: colorWithOpacity(Colors.blue, 0.2),
                          borderStrokeWidth: 3,
                          borderColor: Colors.blue,
                        )),
                    if (tempPolygonPoints.length >= 2)
                      Polygon(
                        points: tempPolygonPoints,
                        color: colorWithOpacity(Colors.red, 0.15),
                        borderStrokeWidth: 2,
                        borderColor: Colors.red,
                      ),
                  ],
                ),
                if (currentMode == MapMode.polygon &&
                    tempPolygonPoints.isNotEmpty &&
                    liveLinePoint != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [tempPolygonPoints.last, liveLinePoint!],
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ...geoPoints.map((m) => Marker(
                          width: 24,
                          height: 24,
                          point: m.latLng,
                          child: GestureDetector(
                            onTap: () =>
                                _showMarkerInfo(context, m.name, m.description),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        )),
                    if (tempMarkerPoint != null)
                      Marker(
                        width: 16,
                        height: 16,
                        point: tempMarkerPoint!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ...tempPolygonPoints.map((point) => Marker(
                          width: 14,
                          height: 14,
                          point: point,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.6 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      currentMode == MapMode.marker
                          ? "Nokta Modu"
                          : "Alan Modu",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    backgroundColor: currentMode == MapMode.marker
                        ? Colors.blue
                        : Colors.red,
                    onPressed: _toggleMode,
                    child: Icon(
                      currentMode == MapMode.marker
                          ? Symbols.timeline // DİKKAT: Doğru class!
                          : Symbols.highlight_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: currentMode == MapMode.marker
                        ? "Alan Moduna Geç"
                        : "Nokta Moduna Geç",
                  ),
                ],
              ),
            ),
            if (currentMode == MapMode.marker && tempMarkerPoint != null)
              Positioned(
                bottom: 30,
                left: 30,
                right: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _cancelMarker,
                      icon: const Icon(Icons.cancel),
                      label: const Text("İptal"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _saveMarker(context),
                      icon: const Icon(Icons.save),
                      label: const Text("Kaydet"),
                    ),
                  ],
                ),
              ),
            if (currentMode == MapMode.polygon && tempPolygonPoints.isNotEmpty)
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade200,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _undoPolygonPoint,
                      icon: const Icon(Icons.undo),
                      label: const Text("Geri Al"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _cancelPolygon,
                      icon: const Icon(Icons.cancel),
                      label: const Text("İptal"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: tempPolygonPoints.length < 3
                          ? null
                          : () => _savePolygon(context),
                      icon: const Icon(Icons.save),
                      label: const Text("Kaydet"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
