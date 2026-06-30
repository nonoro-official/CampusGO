import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String organizerId;
  final String organizerName;
  final String reason;
  final String description;
  final Timestamp timestamp;
  final String status;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.organizerId,
    required this.organizerName,
    required this.reason,
    required this.description,
    required this.timestamp,
    required this.status,
  });

  factory ReportModel.fromMap(Map<String, dynamic> data, String id) {
    return ReportModel(
      id: id,
      reporterId: data['reporterId'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'reason': reason,
      'description': description,
      'timestamp': timestamp,
      'status': status,
    };
  }
}