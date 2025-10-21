import 'package:atma_farm_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmPinpointScreen extends StatefulWidget {
  const FarmPinpointScreen({super.key});

  @override
  State<FarmPinpointScreen> createState() => _FarmPinpointScreenState();
}

class _FarmPinpointScreenState extends State<FarmPinpointScreen> {
  // Default camera position (center of India)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 4,
  );

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, we can't get the location.
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );
    } catch (e) {
      // Handle error
      print("Error getting location: $e");
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _saveFarmLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final farmData = {
        'ownerUid': user.uid,
        'farmName': "Gita's Main Plot", // Placeholder name for now
        'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create a new document in the 'farms' collection
      await FirebaseFirestore.instance.collection('farms').add(farmData);
      
      if(mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
           (Route<dynamic> route) => false,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save farm location: ${e.toString()}')),
        );
      }
    } finally {
       if (mounted) {
         setState(() {
           _isLoading = false;
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _selectedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selectedFarm'),
                      position: _selectedLocation!,
                    ),
                  },
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Tap on the map to pinpoint your main farm',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveFarmLocation,
                  child: const Text('Confirm Location and Continue'),
                ),
          ),
        ],
      ),
    );
  }
}
