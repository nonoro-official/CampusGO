import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added to filter events by organizer account
import '../../models/event_model.dart';
import '../events/event_detail_screen.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  List<Marker> markers = [];
  final MapController _mapController = MapController();

  // Placement State Flags
  bool _isPlacingPin = false;

  @override
  void initState() {
    super.initState();
    _listenToEvents();
  }

  // Real-time listener for mapped pins
  void _listenToEvents() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    FirebaseFirestore.instance
        .collection("events")
        .where('organizerId', isEqualTo: currentUserId) // Only show this organizer's pinned events
        .snapshots()
        .listen((snapshot) {
      final newMarkers = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['latitude'] != null && data['longitude'] != null;
      }).map((doc) {
        final data = doc.data();
        final event = EventModel.fromMap(data, doc.id);

        // Matching clean icon pin style from the user dashboard
        return Marker(
          point: LatLng(event.latitude!, event.longitude!),
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
                Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
          ),
        );
      }).toList();

      if (mounted) {
        setState(() => markers = newMarkers);
      }
    });
  }

  // Captures coordinate taps on the map canvas layer
  void _handleMapTap(LatLng latLng) {
    setState(() {
      _isPlacingPin = false; // Turn off placement state mode
    });
    _showEventSelectionDialog(latLng);
  }

  // Modal selector connecting physical map locations to Firestore documents
  void _showEventSelectionDialog(LatLng latLng) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    String? selectedEventId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Link Event to Pin", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Coordinates Selected:\nLat: ${latLng.latitude.toStringAsFixed(5)}, Lng: ${latLng.longitude.toStringAsFixed(5)}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text("Select Your Target Event:", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),

              // Querying only events mapped to this logged in organizer account ID
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('organizerId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final eventDocs = snapshot.data!.docs;

                  if (eventDocs.isEmpty) {
                    return const Text(
                      "No events found. Please create an event in your management panel first.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    hint: const Text("Choose Event"),
                    isExpanded: true,
                    items: eventDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unnamed Event', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedEventId = value;
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE46A3E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (selectedEventId != null) {
                  // Inject geospatial telemetry variables into the document
                  await FirebaseFirestore.instance.collection('events').doc(selectedEventId).update({
                    'latitude': latLng.latitude,
                    'longitude': latLng.longitude,
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save Pin", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Replicated modal view setup from the client map view
  void _showEventPreview(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                      event.imageUrl!, width: 85, height: 85, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/campusgo_logo.png', width: 85, height: 85, fit: BoxFit.cover),
                    )
                        : Container(width: 85, height: 85, color: Colors.grey[200], child: Image.asset('assets/images/campusgo_logo.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE46A3E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Interactive Map Canvas Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.6291, 121.0419),
              initialZoom: 17.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onTap: _isPlacingPin ? (tapPosition, latLng) => _handleMapTap(latLng) : null,
            ),
            children: [
              TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.campusgo.app'
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Action Guide Top Bar Banner (Appears only during placement mode)
          if (_isPlacingPin)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _isPlacingPin ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE46A3E),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Tap on the map to place your pin",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _isPlacingPin = false),
                        child: const Icon(Icons.cancel, color: Colors.white70, size: 22),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // Control Action Triggers
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Plus Add Button Configuration Switch
            FloatingActionButton(
              heroTag: "btn_add_event_location",
              backgroundColor: _isPlacingPin ? Colors.grey : const Color(0xFFE46A3E),
              onPressed: () {
                setState(() {
                  _isPlacingPin = !_isPlacingPin;
                });
              },
              child: Icon(_isPlacingPin ? Icons.close : Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "btn_admin_recenter",
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(const LatLng(14.6291, 121.0419), 17.0);
              },
              child: const Icon(Icons.home, color: Color(0xFFE46A3E)),
            ),
          ],
        ),
      ),
    );
  }
}