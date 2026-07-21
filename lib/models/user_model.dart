import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final Role role;
  final Timestamp lastSeen;
  final UserTier userTier;
  final String? organizerId;
  final String? schoolId;
  final String? imageUrl;
  final bool isOnline;
  final int points;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
    required this.lastSeen,
    required this.userTier,
    this.organizerId,
    this.schoolId,
    this.imageUrl,
    this.isOnline = false,
    this.points = 0,
  });

  // Convert Firestore Document to Model
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: Role.fromString(data['role'] ?? 'Customer'),
      lastSeen: data['lastSeen'] is Timestamp
          ? data['lastSeen'] as Timestamp
          : (data['lastOnline'] is Timestamp ? data['lastOnline'] as Timestamp : Timestamp.now()),
      userTier: UserTier.fromString(data['userTier'] ?? 'Free'),
      organizerId: data['organizerId'],
      schoolId: data['schoolId'],
      imageUrl: data['imageUrl'],
      isOnline: data['isOnline'] ?? false,
      points: (data['points'] as num?)?.toInt() ?? 0,
    );
  }

  // Convert Model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role.toName,
      'lastSeen': lastSeen,
      'userTier': userTier.toName,
      'organizerId': organizerId,
      'schoolId': schoolId,
      'imageUrl': imageUrl,
      'isOnline': isOnline,
      'points': points,
    };
  }
}
