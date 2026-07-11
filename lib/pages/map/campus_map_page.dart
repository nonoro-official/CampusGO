import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../events/event_detail_screen.dart';

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
        matchesFilter = location.contains(widget.activeFilter.toLowerCase()) ||
            name.contains(widget.activeFilter.toLowerCase());
      }

      // Only show events that have valid coordinates
      return matchesSearch && matchesFilter && data['latitude'] != null && data['longitude'] != null;
    }).map((doc) {
      final data = doc.data();
      final event = EventModel.fromMap(data, doc.id);

      // Render clean, lightweight pins on the map layer
      return Marker(
        point: LatLng(data["latitude"], data["longitude"]),
        width: 45,
        height: 45,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showEventPreview(context, event),
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFE46A3E),
            size: 40,
            shadows: [
              Shadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 3),
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

  // Summary sheet overlay triggered exclusively when a pin is pressed
  void _showEventPreview(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Display Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                      event.imageUrl!,
                      width: 85,
                      height: 85,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/campusgo_logo.png',
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      width: 85,
                      height: 85,
                      color: Colors.grey[200],
                      child: Image.asset('assets/images/campusgo_logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Summaries & Floor Placements
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.layers, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "${event.location}${event.floor != null ? ' (Floor ${event.floor})' : ''}",
                              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Bottom Action Navigation Route Link
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE46A3E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Dismiss summary dialog frame view
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                    );
                  },
                  child: const Text(
                    "View Event Details",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
          initialZoom: 17.0,
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
        padding: const EdgeInsets.only(bottom: 120.0), // Kept padding spacing layout safe above your nav bar
        child: FloatingActionButton(
          heroTag: "btn_recenter",
          backgroundColor: Colors.white,
          onPressed: () {
            _mapController.move(const LatLng(14.6291, 121.0419), 17.0);
          },
          child: const Icon(Icons.home, color: Color(0xFFE46A3E)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}