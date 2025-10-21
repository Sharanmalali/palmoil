import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atma_farm_app/screens/farm_details_screen.dart'; // Import the new details screen

class FarmPinpointScreen extends StatefulWidget {
  const FarmPinpointScreen({super.key});

  @override
  State<FarmPinpointScreen> createState() => _FarmPinpointScreenState();
}

class _FarmPinpointScreenState extends State<FarmPinpointScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  LatLng _initialPosition = const LatLng(20.5937, 78.9629); // Default to India
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        setState(() => _isLoading = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      setState(() => _isLoading = false);
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      if(mounted){
        setState(() {
          _initialPosition = LatLng(position.latitude, position.longitude);
          _selectedLocation = _initialPosition;
          _isLoading = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
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
        const SnackBar(content: Text('Please select a location by tapping on the map.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user logged in.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Create a new document in the 'farms' collection
      final newFarmDoc = await FirebaseFirestore.instance.collection('farms').add({
        'ownerUid': user.uid,
        'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to the FarmDetailsScreen, passing the ID of the new document
      if(mounted){
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FarmDetailsScreen(farmId: newFarmDoc.id),
          ),
        );
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save location: $e')));
    } finally {
       if(mounted){
        setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinpoint Your Farm'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12),
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location and Continue'),
              onPressed: _isLoading ? null : _saveFarmLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}

