import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/event_model.dart';
import '../events/event_detail_screen.dart';
import '../rewards/qr_scanner_page.dart';

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

  @override
  void initState() {
    super.initState();
    _listenToEvents();
  }

  void _listenToEvents() {
    FirebaseFirestore.instance.collection('events').snapshots().listen((snapshot) {
      _updateMarkers(snapshot.docs);
    });
  }

  void _updateMarkers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final query = widget.searchQuery.toLowerCase().trim();

    final newMarkers = docs.where((doc) {
      final data = doc.data();
      final String name = (data['name'] ?? '').toString().toLowerCase();
      final String location = (data['location'] ?? '').toString().toLowerCase();
      final String desc = (data['description'] ?? '').toString().toLowerCase();

      bool matchesSearch = query.isEmpty ||
          name.contains(query) ||
          desc.contains(query) ||
          location.contains(query);

      bool matchesFilter = true;
      if (widget.activeFilter != "All") {
        // Assuming filters could be floors or specific event types if they were added
        // For now, simple location/name match for filter if it's not "All"
        matchesFilter = location.contains(widget.activeFilter.toLowerCase()) || 
                        name.contains(widget.activeFilter.toLowerCase());
      }

      // Only show events that have coordinates
      return matchesSearch && matchesFilter && data['latitude'] != null && data['longitude'] != null;
    }).map((doc) {
      final data = doc.data();
      final event = EventModel.fromMap(data, doc.id);
      String imageUrl = data['imageUrl'] ?? '';

      return Marker(
        point: LatLng(data["latitude"], data["longitude"]),
        width: 160,
        height: 85,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showEventPreview(context, event),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                      child: Container(
                        width: 24,
                        height: 24,
                        color: Colors.grey.shade200,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/campusgo_logo.png', fit: BoxFit.cover),
                        )
                            : Image.asset('assets/images/campusgo_logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.black
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${event.location}${event.floor != null ? ' - ${event.floor}' : ''}",
                            style: const TextStyle(fontSize: 8, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.location_on,
                color: Color(0xFFE46A3E),
                size: 35,
                shadows: [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))],
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (mounted) {
      setState(() {
        markers = newMarkers;
      });
    }
  }

  void _showEventPreview(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(event.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                        : Container(width: 80, height: 80, color: Colors.grey[200], child: Image.asset('assets/images/campusgo_logo.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("${event.location}${event.floor != null ? ' - ${event.floor}' : ''}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
                  },
                  child: const Text("View Event Details", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant UserMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery || oldWidget.activeFilter != widget.activeFilter) {
      FirebaseFirestore.instance.collection('events').get().then((snapshot) {
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
          initialZoom: 17.0, // Zoomed in more for campus view
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', 
            userAgentPackageName: 'com.campusgo.app'
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "btn_scan",
              backgroundColor: Colors.amber.shade700,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MockQRScannerPage())),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text("Scan to Earn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            FloatingActionButton(
              heroTag: "btn_recenter",
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(const LatLng(14.6291, 121.0419), 17.0);
              },
              child: const Icon(Icons.home, color: Color(0xFFE46A3E)),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
