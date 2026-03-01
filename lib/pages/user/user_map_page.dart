import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_restaurant_detail_page.dart'; // Make sure this is imported!

class UserMapPage extends StatelessWidget {
  final String searchQuery;
  final String activeFilter;

  const UserMapPage({
    super.key,
    required this.searchQuery,
    required this.activeFilter,
  });

  void _showRestaurantPreview(BuildContext context, String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String imageUrl = data['imageUrl'] ?? '';
        String name = data['name'] ?? 'Unknown Restaurant';
        String cuisine = data['cuisine'] ?? 'Various';
        String price = data['priceRange'] ?? '₱';
        String hours = data['operatingHours'] ?? 'Hours unlisted';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 150, fit: BoxFit.cover)
                    : Container(height: 120, color: Colors.grey.shade200, child: const Icon(Icons.restaurant, size: 50, color: Colors.grey)),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("$cuisine • $price", style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Color(0xFFE46A3E)),
                        const SizedBox(width: 5),
                        Text(hours, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserRestaurantDetailPage(
                              restaurantId: id,
                              data: data,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE46A3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Center(child: Text("View Menu & Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("restaurants").snapshots(),
      builder: (context, snapshot) {
        // If loading, just show an empty map skeleton
        if (!snapshot.hasData) {
          return FlutterMap(
            options: MapOptions(initialCenter: const LatLng(14.6291, 121.0419), initialZoom: 16.0),
            children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')],
          );
        }

        // 1. Filter the restaurants based on Search and Chips!
        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (!data.containsKey("latitude") || !data.containsKey("longitude")) return false;

          // Search Bar Check
          if (searchQuery.isNotEmpty) {
            String name = (data['name'] ?? '').toString().toLowerCase();
            if (!name.contains(searchQuery.toLowerCase())) return false;
          }

          // Filter Chip Check
          if (activeFilter != "All") {
            if (activeFilter == "Free WiFi") {
              if (data['hasWiFi'] != true) return false;
            } else if (activeFilter.startsWith("₱")) {
              if (data['priceRange'] != activeFilter) return false;
            } else {
              if (data['cuisine'] != activeFilter) return false;
            }
          }

          return true;
        }).toList();

        // 2. Generate the blue map pins from the filtered list
        List<Marker> markers = filteredDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Marker(
            point: LatLng(data["latitude"], data["longitude"]),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showRestaurantPreview(context, doc.id, data),
              child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
            ),
          );
        }).toList();

        // 3. Draw the map with only the matching pins
        return FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(14.6291, 121.0419),
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.foodika.app'),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }
}