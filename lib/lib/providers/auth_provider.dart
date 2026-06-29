import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// 1. Watch the raw Firebase User (Internal Firebase state)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Watch the Firestore Document (Your actual App User data)
final userDocProvider = StreamProvider<UserModel?>((ref) {
  // We watch the raw auth state
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);

      // Link the Firestore stream to the current UID
      return FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map(
            (snap) =>
                snap.exists ? UserModel.fromMap(snap.data()!, snap.id) : null,
          );
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// 3. Helper for the rest of the app
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(userDocProvider).value;
});

// Stream of a specific user's online flag (used for vendor availability)
final userOnlineStatusProvider = StreamProvider.family<bool, String>((
  ref,
  uid,
) {
  // avoid importing Firestore at the top of auth_provider? we'll import now
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => (doc.data()?['isOnline'] ?? false) as bool);
});
