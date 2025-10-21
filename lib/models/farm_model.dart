import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// This class represents a single Farm document from Firestore
class Farm {
  final String id;
  final String ownerUid;
  final LatLng location;
  final Timestamp? plantationDate; // It can be null

  Farm({
    required this.id,
    required this.ownerUid,
    required this.location,
    this.plantationDate,
  });

  // A factory constructor to create a Farm instance from a Firestore document
  factory Farm.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint;

    return Farm(
      id: doc.id,
      ownerUid: data['ownerUid'],
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      plantationDate: data['plantationDate'] as Timestamp?,
    );
  }
}
