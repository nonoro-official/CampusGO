import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_detail/restaurant_detail_dashboard.dart';

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
    FirebaseFirestore.instance.collection("restaurants").snapshots().listen((snapshot) {
      final newMarkers = snapshot.docs.map((doc) {
        final data = doc.data();

        // Safely extract coordinates
        double lat = data["latitude"] ?? 0.0;
        double lng = data["longitude"] ?? 0.0;

        return Marker(
          point: LatLng(lat, lng),
          width: 160,
          height: 90,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RestaurantDetailDashboard(restaurantId: doc.id, restaurantData: data),
            )),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: (data['imageUrl'] != null && data['imageUrl'] != "")
                            ? Image.network(data['imageUrl'], width: 35, height: 35, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 30))
                            : const Icon(Icons.restaurant, size: 30),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                data['name'] ?? 'Place',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                    "${data['avgRating'] ?? '0.0'}",
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(width: 2),
                                Text(
                                    "(${data['reviewCount'] ?? '0'})",
                                    style: const TextStyle(fontSize: 10, color: Colors.grey)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.location_on, color: Color(0xFFE46A3E), size: 30),
              ],
            ),
          ),
        );
      }).toList();

      setState(() => markers = newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
          initialCenter: LatLng(14.6291, 121.0419), // Quezon City Default
          initialZoom: 16.0
      ),
      children: [
        TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'),
        MarkerLayer(markers: markers),
      ],
    );
  }
}