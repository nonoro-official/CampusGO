import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final DateTime date;        // Start Date
  final DateTime endDate;     // End Date
  final String location;
  final String? floor;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<String> attendingOrganizerIds;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.endDate,
    required this.location,
    this.floor,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.attendingOrganizerIds = const [],
  });

  bool get isEnded {
    final now = DateTime.now();
    // Use the end of the day for the endDate to be fair
    final endOfEventDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return now.isAfter(endOfEventDay);
  }

  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime startDate = data['date'] is Timestamp
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();

    return EventModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      date: startDate,
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : startDate, // Fallback to start date if end is missing
      location: data['location'] ?? '',
      floor: data['floor'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'],
      attendingOrganizerIds: List<String>.from(data['attendingOrganizerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'floor': floor,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'attendingOrganizerIds': attendingOrganizerIds,
    };
  }
}
