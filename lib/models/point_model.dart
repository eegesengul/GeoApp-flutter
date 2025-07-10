import 'package:latlong2/latlong.dart';

class PointModel {
  final String id;
  final String name;
  final String description;
  final LatLng latLng;

  PointModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latLng,
  });

  factory PointModel.fromGeoJson(Map<String, dynamic> json) {
    final coords = json['geometry']['coordinates'];
    return PointModel(
      id: json['properties']['id'].toString(),
      name: json['properties']['name'] ?? "",
      description: json['properties']['description'] ?? "",
      latLng: LatLng(coords[1], coords[0]),
    );
  }
}
