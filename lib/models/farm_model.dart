import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Farm {
  final String id;
  final LatLng location;
  final Timestamp? plantationDate;
  // Add the new fields
  final String? waterSource;
  final String? soilType;

  Farm({
    required this.id,
    required this.location,
    this.plantationDate,
    // Add to constructor
    this.waterSource,
    this.soilType,
  });

  factory Farm.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    GeoPoint geoPoint = data['location'];

    // Safely get the new fields
    final waterSource = data.containsKey('waterSource') ? data['waterSource'] as String? : null;
    final soilType = data.containsKey('soilType') ? data['soilType'] as String? : null;

    return Farm(
      id: doc.id,
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      plantationDate: data['plantationDate'] as Timestamp?,
      waterSource: waterSource,
      soilType: soilType,
    );
  }
}