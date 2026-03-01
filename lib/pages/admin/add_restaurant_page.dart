import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final contactController = TextEditingController();
  final hoursController = TextEditingController();

  String selectedCuisine = 'Filipino';
  final List<String> cuisines = ['Filipino', 'Fast Food', 'Cafe', 'Dessert', 'Street Food', 'Healthy', 'Other'];

  String selectedPrice = '₱ (Budget)';
  final List<String> prices = ['₱ (Budget)', '₱₱ (Moderate)', '₱₱₱ (Expensive)'];

  bool acceptsGCash = false;
  bool acceptsCards = false;
  bool hasParking = false;
  bool hasWiFi = false;

  LatLng? selectedLocation;
  File? selectedImage;
  bool isSaving = false;

  void pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  void saveRestaurant() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a restaurant name.")));
      return;
    }
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please tap the map to select a location.")));
      return;
    }

    setState(() => isSaving = true);
    String finalImageUrl = "";

    try {
      if (selectedImage != null) {
        final ref = FirebaseStorage.instance.ref("restaurants/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putFile(selectedImage!);
        finalImageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection("restaurants").add({
        "name": nameController.text.trim(),
        "address": addressController.text.trim(),
        "description": descriptionController.text.trim(),
        "contactNumber": contactController.text.trim(),
        "operatingHours": hoursController.text.trim(),
        "cuisine": selectedCuisine,
        "priceRange": selectedPrice,
        "acceptsGCash": acceptsGCash,
        "acceptsCards": acceptsCards,
        "hasParking": hasParking,
        "hasWiFi": hasWiFi,
        "latitude": selectedLocation!.latitude,
        "longitude": selectedLocation!.longitude,
        "imageUrl": finalImageUrl,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Restaurant"),
        backgroundColor: const Color(0xFFE46A3E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name *")),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact Number", hintText: "e.g. 0917 123 4567"), keyboardType: TextInputType.phone),
            TextField(
              controller: hoursController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Operating Hours *",
                hintText: "Tap to select opening and closing times",
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
            ),            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
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

            const Text("Location & Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            const SizedBox(height: 10),
            const Text("Tap the map to set the location *", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(14.6291, 121.0419),
                  initialZoom: 16.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  onTap: (tapPosition, point) => setState(() => selectedLocation = point),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.foodika.app'),
                  if (selectedLocation != null)
                    MarkerLayer(markers: [Marker(point: selectedLocation!, width: 50, height: 50, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(selectedImage == null ? "Add Image (Opt.)" : "Image Selected"),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveRestaurant,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                  child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Save Place"),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}