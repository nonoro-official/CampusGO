import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../events/event_detail_screen.dart';

class AdminMapPage extends ConsumerStatefulWidget {
  const AdminMapPage({super.key});

  @override
  ConsumerState<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends ConsumerState<AdminMapPage> {
  final MapController _mapController = MapController();
  bool _isPlacingPin = false;

  void _handleMapTap(LatLng latLng) {
    setState(() => _isPlacingPin = false);
    _showEventSelectionDialog(latLng);
  }

  void _showEventSelectionDialog(LatLng latLng) {
    final user = ref.read(currentUserProvider);
    final organizerId = user?.organizerId;
    if (organizerId == null) return;

    String? selectedEventId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Link Event to Pin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Lat: ${latLng.latitude.toStringAsFixed(5)}, Lng: ${latLng.longitude.toStringAsFixed(5)}", style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('events').where('creatorId', isEqualTo: organizerId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Text("No events found. Create one first.");
                  return DropdownButtonFormField<String>(
                    hint: const Text("Choose Event"),
                    items: docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['name'] ?? 'Unnamed'))).toList(),
                    onChanged: (v) => selectedEventId = v,
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedEventId != null) {
                  await FirebaseFirestore.instance.collection('events').doc(selectedEventId).update({'latitude': latLng.latitude, 'longitude': latLng.longitude});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizerId = ref.watch(currentUserProvider)?.organizerId;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.6291, 121.0419),
              initialZoom: 17.0,
              onTap: _isPlacingPin ? (tapPos, latLng) => _handleMapTap(latLng) : null,
            ),
            children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("events").snapshots(),
                builder: (context, snapshot) {
                  final markers = <Marker>[];
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['latitude'] != null && data['longitude'] != null) {
                        final event = EventModel.fromMap(data, doc.id);
                        final isMyEvent = data['creatorId'] == organizerId;
                        
                        markers.add(Marker(
                          point: LatLng(event.latitude!, event.longitude!),
                          width: 45, height: 45,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isMyEvent)
                                        const Align(
                                          alignment: Alignment.topRight,
                                          child: Chip(
                                            label: Text("My Event", style: TextStyle(fontSize: 10)), 
                                            backgroundColor: Color(0xFFFFE0B2) // Light orange
                                          ),
                                        ),
                                      Text(event.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
                                        },
                                        child: const Text("Details"),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.location_on, 
                              color: isMyEvent ? const Color(0xFFE46A3E) : Colors.blueGrey, 
                              size: 40
                            ),
                          ),
                        ));
                      }
                    }
                  }
                  return MarkerLayer(markers: markers);
                },
              ),
            ],
          ),
          if (_isPlacingPin)
            Positioned(
              top: 70, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE46A3E), borderRadius: BorderRadius.circular(30)),
                child: const Text("Tap on map to place pin", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: "add_pin",
              backgroundColor: _isPlacingPin ? Colors.grey : const Color(0xFFE46A3E),
              onPressed: () => setState(() => _isPlacingPin = !_isPlacingPin),
              child: Icon(_isPlacingPin ? Icons.close : Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "recenter",
              onPressed: () => _mapController.move(const LatLng(14.6291, 121.0419), 17.0),
              child: const Icon(Icons.home),
            ),
          ],
        ),
      ),
    );
  }
}
