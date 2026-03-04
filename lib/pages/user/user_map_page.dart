import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // NEW: GPS tracking
import 'dart:async'; // NEW: For the continuous location stream
import 'user_restaurant_detail_page.dart';

class UserMapPage extends StatefulWidget {
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

  LatLng? _currentLocation; // Tracks your exact position
  StreamSubscription<Position>? _positionStreamSubscription; // Listens while you walk

  @override
  void initState() {
    super.initState();
    _listenToRestaurants();
    _startLocationTracking(); // Initialize GPS tracking on startup
  }

  // =========================================================
  // NEW: Real-time GPS Tracking System
  // =========================================================
  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if GPS is turned on
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    // 2. Ask the user for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    // 3. Get initial quick location
    Position initialPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
    });

    // Smoothly pan the camera to the user's real location!
    _mapController.move(_currentLocation!, 15.0);

    // 4. Start the live tracking stream (updates every 5 meters you walk)
    _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        )
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    // Stop tracking when the map is closed to save battery
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // EXISTING RESTAURANT LOGIC (Untouched)
  // =========================================================
  void _listenToRestaurants() {
    FirebaseFirestore.instance.collection('restaurants').snapshots().listen((snapshot) {
      _updateMarkers(snapshot.docs);
    });
  }

  void _updateMarkers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final newMarkers = docs.where((doc) {
      final data = doc.data();
      final String name = (data['name'] ?? '').toString().toLowerCase();
      final String cuisine = (data['cuisine'] ?? '').toString().toLowerCase();
      final String filter = widget.activeFilter.toLowerCase();
      final String search = widget.searchQuery.toLowerCase();

      bool matchesSearch = name.contains(search) || cuisine.contains(search);
      bool matchesFilter = filter == 'all' || cuisine == filter;

      return matchesSearch && matchesFilter;
    }).map((doc) {
      final data = doc.data();
      double lat = data["latitude"] ?? 0.0;
      double lng = data["longitude"] ?? 0.0;

      return Marker(
        point: LatLng(lat, lng),
        width: 160,
        height: 90,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserRestaurantDetailPage(restaurantId: doc.id, data: data),
          )),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (data['avgRating'] != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text("${data['avgRating']} (${data['reviewCount'] ?? 0})", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
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
    if (oldWidget.searchQuery != widget.searchQuery || oldWidget.activeFilter != widget.activeFilter) {
      FirebaseFirestore.instance.collection('restaurants').get().then((snapshot) {
        _updateMarkers(snapshot.docs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine the untouched restaurant pins with your NEW green live tracking pin!
    List<Marker> allMarkers = List.from(markers);

    if (_currentLocation != null) {
      allMarkers.add(
          Marker(
            point: _currentLocation!,
            width: 60,
            height: 60,
            child: const Column(
              children: [
                Icon(Icons.person_pin_circle, color: Colors.green, size: 45),
              ],
            ),
          )
      );
    }

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(14.6291, 121.0419), // Fallback center while GPS loads
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          ),
          MarkerLayer(
            markers: allMarkers,
          ),
        ],
      ),
      // NEW: A floating button just above the active order tracker to snap back to your location
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0), // Kept high so it doesn't block your ActiveOrderTracker
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () {
            if (_currentLocation != null) {
              _mapController.move(_currentLocation!, 16.0);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fetching GPS... please wait."))
              );
            }
          },
          child: const Icon(Icons.my_location, color: Colors.green),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}