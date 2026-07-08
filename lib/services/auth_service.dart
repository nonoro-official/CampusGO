import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/enums.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      // This creates a real-time listener to the Firestore document
      return _db.collection('users').doc(firebaseUser.uid).snapshots().map((
        doc,
      ) {
        if (!doc.exists || doc.data() == null) return null;
        return UserModel.fromMap(doc.data()!, doc.id);
      });
    });
  }

  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required Role role,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = result.user!.uid;

    // 🔥 Force refresh token so email is available in rules
    await result.user!.getIdToken(true);

    await _db.collection('users').doc(uid).set({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role.toName,
      'organizerId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return uid;
  }

  Future<Role> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await updateUserStatus(true); // Set user as online on login

    final DocumentSnapshot doc = await _db
        .collection('users')
        .doc(result.user!.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      final user = UserModel.fromMap(data, doc.id);
      return user.role;
    }

    throw Exception("Account data not found in Firestore. Please register again.");
  }

  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;
    final doc = await _db.collection('users').doc(currentUser!.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection('users').doc(uid).update(data);

      if (data.containsKey('email')) {
        final newEmail = data['email'];
        final user = _auth.currentUser;

        if (user != null && newEmail != user.email) {
          await user.verifyBeforeUpdateEmail(newEmail);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          "For security, please log out and log back in before changing your email.",
        );
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Failed to update profile: $e");
    }
  }

  Future<void> signOut() async {
    await updateUserStatus(false);
    await _auth.signOut();
  }

  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    // Delete Auth user (this signs them out too)
    await user.delete();
    // Delete Firestore doc
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> resetPassword(String email) async =>
      await _auth.sendPasswordResetEmail(email: email);

  Future<void> updateUserStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String extension = p.extension(imageFile.path);
      Reference ref = _storage
          .ref()
          .child('user_profiles')
          .child('${user.uid}$extension');

      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      await _db.collection('users').doc(user.uid).update({
        'imageUrl': downloadUrl,
      });
    } catch (e) {
      throw Exception("User PFP Upload failed: $e");
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      throw Exception("User not authenticated");
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception("Current password is incorrect.");
      } else if (e.code == 'weak-password') {
        throw Exception("New password must be at least 6 characters.");
      } else {
        throw Exception(e.message ?? "Failed to update password.");
      }
    }
  }

  Future<void> deleteAccount({required String password}) async {
    // deletes organizer and products
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception("User not authenticated");
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final organizerQuery = await _db
          .collection('organizers')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      for (var doc in organizerQuery.docs) {
        await deleteOrganizer(organizerId: doc.id, password: password);
      }

      await _db.collection('users').doc(user.uid).delete();

      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception("Incorrect password. Account deletion failed.");
      } else {
        throw Exception(e.message ?? "Failed to delete account.");
      }
    }
  }

  Future<void> deleteOrganizer({
    required String organizerId,
    required String password,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception("User not authenticated");
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final docRef = _db.collection('organizers').doc(organizerId);

      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception("Organizer not found");
      }

      final productsQuery = await _db
          .collection('products')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      for (var productDoc in productsQuery.docs) {
        await productDoc.reference.delete();
      }

      await docRef.delete();

      await updateUserRoleToCustomer();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception("Incorrect password. Organizer closure failed.");
      } else {
        throw Exception(e.message ?? "Failed to close Organizer.");
      }
    }
  }

  Future<void> updateUserRoleToOrganizer() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) throw Exception("User not found");

    if (doc['role'] != 'Organizer') {
      await doc.reference.update({'role': Role.organizer.toName});
    }
  }

  Future<void> updateUserRoleToCustomer() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) throw Exception("User not found");

    if (doc['role'] != 'Customer') {
      await doc.reference.update({'role': Role.customer.toName});
    }
  }
}
