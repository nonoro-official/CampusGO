import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMapPage extends StatefulWidget {
  const UserMapPage({super.key});

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {

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
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(14.6510, 121.0493),
        zoom: 14,
      ),
      markers: markers,
    );
  }
}