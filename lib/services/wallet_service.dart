import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atma_farm_app/models/subsidy_scheme_model.dart';
import 'package:atma_farm_app/models/subsidy_application_model.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<SubsidyScheme>> getAvailableSchemes() async {
    try {
      final snapshot = await _db.collection('subsidy_schemes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SubsidyScheme(
          id: doc.id,
          name: data['name'] ?? 'No Name',
          description: data['description'] ?? 'No Description',
        );
      }).toList();
    } catch (e) {
      print("Error fetching schemes: $e");
      return [];
    }
  }

  Future<List<SubsidyApplication>> getUserApplications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('subsidy_applications')
          .where('farmerUid', isEqualTo: user.uid)
          .get();
      
      return snapshot.docs.map((doc) => SubsidyApplication.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching applications: $e");
      return [];
    }
  }

  // ** NEW METHOD ADDED HERE **
  // Creates a new subsidy application document in Firestore.
  Future<void> applyForScheme(SubsidyScheme scheme) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    try {
      await _db.collection('subsidy_applications').add({
        'farmerUid': user.uid,
        'schemeName': scheme.name,
        'schemeId': scheme.id, // Store the ID for easier lookup
        'status': 'applied', // Initial status
        'appliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error applying for scheme: $e");
      throw Exception("Could not submit application. Please try again.");
    }
  }
}