import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../events/event_detail_screen.dart';

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
    loadEvents();
  }

  void loadEvents() {
    FirebaseFirestore.instance.collection("events").snapshots().listen((snapshot) {
      final newMarkers = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['latitude'] != null && data['longitude'] != null;
      }).map((doc) {
        final data = doc.data();
        final event = EventModel.fromMap(data, doc.id);
        String imageUrl = data['imageUrl'] ?? '';

        return Marker(
          point: LatLng(event.latitude!, event.longitude!),
          width: 160,
          height: 85,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event),
            )),
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

      if (mounted) setState(() => markers = newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
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
    );
  }
}
