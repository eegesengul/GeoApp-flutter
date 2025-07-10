import 'package:latlong2/latlong.dart';

class AreaModel {
  final String id;
  final String name;
  final String description;
  final List<LatLng> points;

  AreaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
  });

  factory AreaModel.fromGeoJson(Map<String, dynamic> json) {
    final coords = json['geometry']['coordinates'][0];
    return AreaModel(
      id: json['properties']['id'].toString(),
      name: json['properties']['name'] ?? "",
      description: json['properties']['description'] ?? "",
      points: (coords as List).map<LatLng>((e) => LatLng(e[1], e[0])).toList(),
    );
  }
}
