import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_restaurant_page.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    loadRestaurants();
  }

  void loadRestaurants() {
    FirebaseFirestore.instance.collection("restaurants")
        .snapshots()
        .listen((snapshot) {

      final newMarkers = snapshot.docs.map((doc) {
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(doc["latitude"], doc["longitude"]),
          infoWindow: InfoWindow(
            title: doc["name"],
            snippet: doc["description"],
          ),
        );
      }).toSet();

      setState(() {
        markers = newMarkers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurant Map")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.6510, 121.0493),
          zoom: 14,
        ),
        markers: markers,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}