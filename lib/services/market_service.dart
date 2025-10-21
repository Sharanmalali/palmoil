import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atma_farm_app/models/ffb_log_model.dart';

class MarketService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetches all pickup requests submitted by the current user
  Future<List<FfbLog>> getUserPickups() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('ffb_logs')
          .where('farmerUid', isEqualTo: user.uid)
          .orderBy('requestedAt', descending: true) // Show newest first
          .get();
      
      return snapshot.docs.map((doc) => FfbLog.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching user pickups: $e");
      return [];
    }
  }

  // Creates a new pickup request in Firestore
  Future<void> requestPickup(double estimatedQuantity, String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    try {
      await _db.collection('ffb_logs').add({
        'farmerUid': user.uid,
        'farmId': farmId,
        'status': 'requested',
        'requestedAt': FieldValue.serverTimestamp(),
        'estimatedQuantityKg': estimatedQuantity,
      });
    } catch (e) {
      print("Error requesting pickup: $e");
      throw Exception("Could not submit pickup request. Please try again.");
    }
  }
}
