import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Must be top-level for background handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are shown automatically by FCM on Android
  // iOS handles it natively too — nothing needed here usually
  await Firebase.initializeApp();
}

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Initialize Firebase first if not already done
    // (Usually done in main.dart, but good to be safe)

    // 2. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 3. Setup Android Channel
      const androidChannel = AndroidNotificationChannel(
        'messages', 'Messages',
        importance: Importance.max,
      );

      await _localNotifs
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 4. Background Handler (Register ONLY here)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _saveToken();
    }

    // 5. Refresh token if it changes
    _messaging.onTokenRefresh.listen(_updateToken);

    // 6. Don't show FCM notification while app is open — let the banner handle it
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  static Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }

  static Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }

  // Call this to show banner while app is in FOREGROUND
  static void handleForegroundMessages(Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}