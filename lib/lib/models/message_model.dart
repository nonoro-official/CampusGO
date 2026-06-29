import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderID;
  final String senderName;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final bool isSeen;

  MessageModel({
    required this.senderID,
    required this.senderName,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    this.isSeen = false,
  });

  // convert to map
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderName': senderName,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'isSeen': isSeen,
    };
  }

  // from map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderID: map['senderID'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverID: map['receiverID'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isSeen: map['isSeen'] ?? false,
    );
  }
}
