import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final descriptionController = TextEditingController();

  LatLng? selectedLocation;
  File? selectedImage;

  void pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  void saveRestaurant() async {

    if (selectedLocation == null || selectedImage == null) return;

    final ref = FirebaseStorage.instance
        .ref("restaurants/${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(selectedImage!);
    String imageUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection("restaurants").add({
      "name": nameController.text,
      "description": descriptionController.text,
      "latitude": selectedLocation!.latitude,
      "longitude": selectedLocation!.longitude,
      "imageUrl": imageUrl,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Restaurant")),
      body: SingleChildScrollView(
        child: Column(
          children: [

            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),

            SizedBox(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(14.6510, 121.0493),
                  zoom: 14,
                ),
                onTap: (position) {
                  setState(() {
                    selectedLocation = position;
                  });
                },
                markers: selectedLocation == null
                    ? {}
                    : {
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: selectedLocation!,
                  )
                },
              ),
            ),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image"),
            ),

            ElevatedButton(
              onPressed: saveRestaurant,
              child: const Text("Save Restaurant"),
            ),
          ],
        ),
      ),
    );
  }
}