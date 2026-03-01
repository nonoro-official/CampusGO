import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EditRestaurantTab extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> data;
  const EditRestaurantTab({super.key, required this.restaurantId, required this.data});

  @override
  State<EditRestaurantTab> createState() => _EditRestaurantTabState();
}

class _EditRestaurantTabState extends State<EditRestaurantTab> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController descriptionController;
  late TextEditingController contactController;
  late TextEditingController hoursController;

  String selectedCuisine = 'Filipino';
  final List<String> cuisines = ['Filipino', 'Fast Food', 'Cafe', 'Dessert', 'Street Food', 'Healthy', 'Other'];

  String selectedPrice = '₱ (Budget)';
  final List<String> prices = ['₱ (Budget)', '₱₱ (Moderate)', '₱₱₱ (Expensive)'];

  bool acceptsGCash = false;
  bool acceptsCards = false;
  bool hasParking = false;
  bool hasWiFi = false;

  LatLng? originalLocation;
  LatLng? selectedLocation;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name']);
    addressController = TextEditingController(text: widget.data['address']);
    descriptionController = TextEditingController(text: widget.data['description'] ?? '');
    contactController = TextEditingController(text: widget.data['contactNumber'] ?? '');
    hoursController = TextEditingController(text: widget.data['operatingHours'] ?? '');

    if (cuisines.contains(widget.data['cuisine'])) selectedCuisine = widget.data['cuisine'];
    if (prices.contains(widget.data['priceRange'])) selectedPrice = widget.data['priceRange'];

    acceptsGCash = widget.data['acceptsGCash'] ?? false;
    acceptsCards = widget.data['acceptsCards'] ?? false;
    hasParking = widget.data['hasParking'] ?? false;
    hasWiFi = widget.data['hasWiFi'] ?? false;

    if (widget.data['latitude'] != null && widget.data['longitude'] != null) {
      originalLocation = LatLng(widget.data['latitude'], widget.data['longitude']);
    } else {
      originalLocation = const LatLng(14.6291, 121.0419);
    }
    selectedLocation = originalLocation;
  }

  void applyChanges() async {
    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).update({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'description': descriptionController.text.trim(),
        'contactNumber': contactController.text.trim(),
        'operatingHours': hoursController.text.trim(),
        'cuisine': selectedCuisine,
        'priceRange': selectedPrice,
        'acceptsGCash': acceptsGCash,
        'acceptsCards': acceptsCards,
        'hasParking': hasParking,
        'hasWiFi': hasWiFi,
        'latitude': selectedLocation!.latitude,
        'longitude': selectedLocation!.longitude,
      });

      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('history').add({
        'action': 'Details Updated',
        'details': 'Updated details, tags, or location',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes Applied!")));
        setState(() => originalLocation = selectedLocation);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    bool hasMoved = selectedLocation != originalLocation;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Restaurant Name")),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact Number"), keyboardType: TextInputType.phone),
            TextField(
              controller: hoursController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Operating Hours",
                suffixIcon: Icon(Icons.access_time, color: Color(0xFFE46A3E)),
              ),
              onTap: () async {
                TimeOfDay? openTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  helpText: "SELECT OPENING TIME",
                );
                if (openTime == null) return;

                if (context.mounted) {
                  TimeOfDay? closeTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 22, minute: 0),
                    helpText: "SELECT CLOSING TIME",
                  );
                  if (closeTime == null) return;

                  if (context.mounted) {
                    setState(() {
                      hoursController.text = "${openTime.format(context)} - ${closeTime.format(context)}";
                    });
                  }
                }
              },
            ),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
            const SizedBox(height: 20),

            const Text("Categorization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCuisine,
              decoration: const InputDecoration(labelText: "Cuisine / Category"),
              items: cuisines.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => selectedCuisine = val!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPrice,
              decoration: const InputDecoration(labelText: "Price Range"),
              items: prices.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => selectedPrice = val!),
            ),
            const SizedBox(height: 20),

            const Text("Features & Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            SwitchListTile(title: const Text("Accepts GCash"), value: acceptsGCash, onChanged: (val) => setState(() => acceptsGCash = val)),
            SwitchListTile(title: const Text("Accepts Credit/Debit Cards"), value: acceptsCards, onChanged: (val) => setState(() => acceptsCards = val)),
            SwitchListTile(title: const Text("Has Parking Space"), value: hasParking, onChanged: (val) => setState(() => hasParking = val)),
            SwitchListTile(title: const Text("Free WiFi"), value: hasWiFi, onChanged: (val) => setState(() => hasWiFi = val)),
            const SizedBox(height: 20),

            const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Adjust pin (tap to move):", style: TextStyle(fontWeight: FontWeight.bold)),
                if (hasMoved)
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      Text(" Old  ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Icon(Icons.location_on, color: Colors.blue, size: 16),
                      Text(" New", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
              ],
            ),
            const SizedBox(height: 10),

            Container(
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: originalLocation!,
                  initialZoom: 16.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  onTap: (tapPosition, point) => setState(() => selectedLocation = point),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.foodika.app'),
                  MarkerLayer(
                    markers: [
                      if (originalLocation != null)
                        Marker(point: originalLocation!, width: 50, height: 50, child: Icon(Icons.location_on, color: hasMoved ? Colors.red.withOpacity(0.4) : Colors.red, size: 40)),
                      if (hasMoved)
                        Marker(point: selectedLocation!, width: 50, height: 50, child: const Icon(Icons.location_on, color: Colors.blue, size: 40))
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Discard"))),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : applyChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Apply Changes", style: TextStyle(color: Colors.white)),
                    )
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}