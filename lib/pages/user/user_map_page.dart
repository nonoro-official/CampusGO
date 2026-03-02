import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_restaurant_detail_page.dart';

class UserMapPage extends StatefulWidget {
  // FIXED: Added these two named parameters to the constructor
  final String searchQuery;
  final String activeFilter;

  const UserMapPage({
    super.key,
    required this.searchQuery,
    required this.activeFilter,
  });

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {
  List<Marker> markers = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // We listen to the stream, but we will filter the results in the build logic
    _listenToRestaurants();
  }

  void _listenToRestaurants() {
    FirebaseFirestore.instance.collection('restaurants').snapshots().listen((snapshot) {
      _updateMarkers(snapshot.docs);
    });
  }

  void _updateMarkers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final newMarkers = docs.where((doc) {
      final data = doc.data();
      final String name = (data['name'] ?? '').toString().toLowerCase();
      final String cuisine = (data['cuisine'] ?? '').toString();
      final String priceRange = (data['priceRange'] ?? '').toString();

      // 1. Search Filter Logic
      bool matchesSearch = name.contains(widget.searchQuery.toLowerCase());

      // 2. Category/Pill Filter Logic
      bool matchesFilter = true;
      if (widget.activeFilter != "All") {
        if (widget.activeFilter == "Budget") {
          matchesFilter = priceRange == "₱" || priceRange == "₱₱";
        } else {
          matchesFilter = cuisine == widget.activeFilter;
        }
      }

      return matchesSearch && matchesFilter;
    }).map((doc) {
      final data = doc.data();
      double lat = (data['latitude'] ?? 0.0).toDouble();
      double lng = (data['longitude'] ?? 0.0).toDouble();
      String name = data['name'] ?? 'Restaurant';
      String imageUrl = data['imageUrl'] ?? '';
      double avgRating = (data['avgRating'] ?? 0.0).toDouble();
      int reviewCount = (data['reviewCount'] ?? 0).toInt();

      return Marker(
        point: LatLng(lat, lng),
        width: 160,
        height: 90,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserRestaurantDetailPage(
                  restaurantId: doc.id,
                  data: data,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
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
                      child: (imageUrl.isNotEmpty)
                          ? Image.network(imageUrl, width: 35, height: 35, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 25))
                          : const Icon(Icons.restaurant, size: 25, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              Text(
                                " $avgRating",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " ($reviewCount)",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
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

    setState(() {
      markers = newMarkers;
    });
  }

  @override
  void didUpdateWidget(covariant UserMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This triggers when the user types in the search bar or changes a filter
    if (oldWidget.searchQuery != widget.searchQuery || oldWidget.activeFilter != widget.activeFilter) {
      FirebaseFirestore.instance.collection('restaurants').get().then((snapshot) {
        _updateMarkers(snapshot.docs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(14.6291, 121.0419),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}