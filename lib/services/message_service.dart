import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for the current user's name to avoid redundant Firestore fetches
  static String? _cachedSenderName;
  static String? _cachedUserId;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return {...user, 'uid': doc.id};
      }).toList();
    });
  }

  Stream<Set<String>> getChatPartnersStream(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final Set<String> partnerIds = {};
      for (var doc in snapshot.docs) {
        final List<dynamic> participants = doc.data()['participants'] ?? [];
        for (var id in participants) {
          if (id != currentUserId) {
            partnerIds.add(id.toString());
          }
        }
      }
      return partnerIds;
    });
  }

  Stream<List<Map<String, dynamic>>> getChatRoomsStream(String currentUserId) {
    // Note: We removed the orderBy from the query to avoid requiring a composite index.
    // We sort in-memory instead.
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();

      // Sort by timestamp descending (most recent first)
      rooms.sort((a, b) {
        final t1 = a['lastTimestamp'] as Timestamp?;
        final t2 = b['lastTimestamp'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      return rooms;
    });
  }

  Future<void> initiateContact(String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    final docRef = _firestore.collection("chat_rooms").doc(chatRoomID);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'participants': [currentUserID, receiverID],
        'contactInitiatedBy': [currentUserID],
        'createdAt': Timestamp.now(),
        'lastTimestamp': Timestamp.now(),
      });
    } else {
      await docRef.set({
        'contactInitiatedBy': FieldValue.arrayUnion([currentUserID]),
      }, SetOptions(merge: true));
    }
  }

  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // 1. Get Sender Name (Try cache first, then fetch)
    String senderName = 'Unknown';
    if (_cachedUserId == currentUserID && _cachedSenderName != null) {
      senderName = _cachedSenderName!;
    } else {
      final userDoc =
          await _firestore.collection('users').doc(currentUserID).get();
      final userData = userDoc.data();

      if (userData != null) {
        final String? organizerNameInUser = userData['organizerName'];
        final String? organizerId = userData['organizerId'];

        if (organizerNameInUser != null && organizerNameInUser.isNotEmpty) {
          senderName = organizerNameInUser;
        } else if (organizerId != null && organizerId.isNotEmpty) {
          final organizerDoc =
              await _firestore.collection('organizers').doc(organizerId).get();
          if (organizerDoc.exists) {
            senderName = organizerDoc.data()?['organizerName'] ?? senderName;
          }
        } else {
          final String firstName = userData['firstName'] ?? '';
          final String lastName = userData['lastName'] ?? '';
          senderName = '$firstName $lastName'.trim();
          if (senderName.isEmpty) {
            senderName = firstName.isNotEmpty ? firstName : 'Unknown';
          }
        }

        // Cache it for future messages
        _cachedUserId = currentUserID;
        _cachedSenderName = senderName;
      }
    }

    MessageModel newMessage = MessageModel(
      senderID: currentUserID,
      senderName: senderName,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    final batch = _firestore.batch();

    final roomRef = _firestore.collection("chat_rooms").doc(chatRoomID);
    batch.set(
        roomRef,
        {
          'participants': FieldValue.arrayUnion([currentUserID, receiverID]),
          'lastMessage': message,
          'lastTimestamp': timestamp,
          'lastSenderID': currentUserID,
          'lastSenderName': senderName,
          'lastSeen_$currentUserID': timestamp,
        },
        SetOptions(merge: true));

    final msgRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc();
    batch.set(msgRef, newMessage.toMap());

    await batch.commit();
  }

  Future<void> markAsRead(String otherUserID) async {
    final String? currentUserID = _auth.currentUser?.uid;
    if (currentUserID == null) return;

    List<String> ids = [currentUserID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Update room metadata
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'lastSeen_$currentUserID': Timestamp.now(),
    }, SetOptions(merge: true));

    // Update individual messages.
    // We fetch all messages and filter in-memory if needed to avoid index issues,
    // though usually equality filters on two fields are fine.
    // However, to be safest:
    try {
      final unreadMessages = await _firestore
          .collection("chat_rooms")
          .doc(chatRoomID)
          .collection("messages")
          .where('senderID', isEqualTo: otherUserID)
          .where('isSeen', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'isSeen': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> id = [userID, otherUserID];
    id.sort();
    String chatRoomID = id.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp')
        .snapshots();
  }
}
