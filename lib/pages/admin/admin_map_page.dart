import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_detail/restaurant_detail_dashboard.dart'; // Import the dashboard

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    loadRestaurants();
  }

  void loadRestaurants() {
    FirebaseFirestore.instance.collection("restaurants")
        .snapshots()
        .listen((snapshot) {

      final newMarkers = snapshot.docs
          .where((doc) => doc.data().containsKey("latitude") && doc.data().containsKey("longitude"))
          .map((doc) {
        final data = doc.data();
        return Marker(
          point: LatLng(data["latitude"], data["longitude"]),
          // Increased size so the text label doesn't get clipped
          width: 120,
          height: 80,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailDashboard(
                    restaurantId: doc.id,
                    restaurantData: data,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. The always-visible Name Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
                    ],
                  ),
                  child: Text(
                    data["name"] ?? "Unnamed",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis, // Prevents super long names from breaking the UI
                    maxLines: 1,
                  ),
                ),

                // 2. The Map Pin
                const Icon(Icons.location_on, color: Color(0xFFE46A3E), size: 40),
              ],
            ),
          ),
        );
      }).toList();

      setState(() {
        markers = newMarkers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(14.6291, 121.0419), // Centered on CIIT
        initialZoom: 16.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Rotation locked!
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.foodika.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}