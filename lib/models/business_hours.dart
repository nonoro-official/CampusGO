import 'package:flutter/material.dart';

class BusinessHours {
  final int open; // Format: HHmm (e.g., 830)
  final int close; // Format: HHmm (e.g., 2200)

  BusinessHours({required this.open, required this.close});

  // Converts Firestore Map to BusinessHours Class
  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    return BusinessHours(open: map['open'] ?? 0, close: map['close'] ?? 0);
  }

  // Converts BusinessHours Class to Map for Firestore
  Map<String, dynamic> toMap() {
    return {'open': open, 'close': close};
  }

  // UI Helper: Converts 830 to "8:30 AM" based on user's phone settings
  String formatRange(BuildContext context) {
    final openTOD = TimeOfDay(hour: open ~/ 100, minute: open % 100);
    final closeTOD = TimeOfDay(hour: close ~/ 100, minute: close % 100);
    return "${openTOD.format(context)} - ${closeTOD.format(context)}";
  }
}
