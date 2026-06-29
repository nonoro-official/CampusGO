import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unimart/views/home/widgets/message_notification_banner.dart';
import 'package:unimart/views/home/chat_page.dart';

class MessageNotificationListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<String?> currentRouteNotifier;
  final ValueNotifier<String?> currentChatReceiverNotifier;

  const MessageNotificationListener({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.currentRouteNotifier,
    required this.currentChatReceiverNotifier,
  });

  @override
  State<MessageNotificationListener> createState() =>
      _MessageNotificationListenerState();
}

class _MessageNotificationListenerState
    extends State<MessageNotificationListener> {

  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  String? _lastMessageId;
  DateTime? _listenerReadyAt;
  String? _activeUserId;

  @override
  void dispose() {
    _hideBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;

        if (currentUser == null) {
          _activeUserId = null;
          _lastMessageId = null;
          _listenerReadyAt = null;
          _hideBanner();
          return widget.child;
        }

        // Also reset when a DIFFERENT user logs in
        if (_activeUserId != currentUser.uid) {
          _lastMessageId = null;
          _listenerReadyAt = null; // ← ADD THIS
        }
        _activeUserId = currentUser.uid;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('participants', arrayContains: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final currentRoute = widget.currentRouteNotifier.value;
            if (currentRoute == '/' ||
                currentRoute == '/login' ||
                currentRoute == '/register' ||
                currentRoute == '/forgot-password') {
              _listenerReadyAt = null;
              _lastMessageId = null;
              _hideBanner();
              return widget.child;
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return widget.child;
            }

            if (_listenerReadyAt == null ) {
              // Give a short grace period (1 frame) before we start reacting
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _listenerReadyAt = DateTime.now());
              });
              return widget.child;
            }

            final chats = snapshot.data!.docs;
            Map<String, dynamic>? bestChatData;
            String? bestChatId;
            String? bestOtherUserId;
            Timestamp? bestLastTimestamp;

            for (var chat in chats) {
              final data = chat.data() as Map<String, dynamic>;
              final lastSenderID = data['lastSenderID'];
              final lastTimestamp = data['lastTimestamp'];
              final lastSeen = data['lastSeen_${currentUser.uid}'];

              if (lastSenderID == null || lastTimestamp == null) continue;
              if (lastSenderID == currentUser.uid) continue;

              bool isUnread = false;
              if (lastSeen == null) {
                isUnread = true;
              } else if (lastSeen is Timestamp && lastTimestamp is Timestamp) {
                isUnread = lastTimestamp.compareTo(lastSeen) > 0;
              }

              if (!isUnread) continue;

              if (bestLastTimestamp == null ||
                  (lastTimestamp is Timestamp &&
                      lastTimestamp.compareTo(bestLastTimestamp) > 0)) {
                final participants = List<String>.from(data['participants'] ?? []);
                final otherUserId = participants.firstWhere(
                      (id) => id != currentUser.uid,
                  orElse: () => '',
                );
                if (otherUserId.isEmpty) continue;

                bestChatData = data;
                bestChatId = chat.id;
                bestOtherUserId = otherUserId;
                bestLastTimestamp = lastTimestamp as Timestamp;
              }
            }

            if (bestChatData == null || bestChatId == null || bestLastTimestamp == null) {
              return widget.child;
            }

            final lastMessage = bestChatData['lastMessage'] as String? ?? '';
            final lastSenderName = bestChatData['lastSenderName'] as String?;
            final messageId = "${bestChatId}_${bestLastTimestamp.millisecondsSinceEpoch}";

            if (messageId != _lastMessageId) {
              _lastMessageId = messageId;
              final messageTime = DateTime.fromMillisecondsSinceEpoch(
                bestLastTimestamp.millisecondsSinceEpoch,
              );
              final isNewMessage = _listenerReadyAt != null &&
                  messageTime.isAfter(_listenerReadyAt!.subtract(const Duration(seconds: 2)));

              if (isNewMessage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _processNotification(lastSenderName, lastMessage, bestOtherUserId!);
                });
              }
            }

            return widget.child;
          },
        );
      },
    );
  }

  void _hideBanner() {
    _hideTimer?.cancel();
    _hideTimer = null;

    if (_overlayEntry != null) {
      final entryToRemove = _overlayEntry;
      _overlayEntry = null;
      try {
        entryToRemove?.remove();
      } catch (_) {}
    }
  }

  Future<String> _resolveSenderName(String senderId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final String? bNameInUser = data['businessName']?.toString();
          if (bNameInUser != null && bNameInUser.isNotEmpty) return bNameInUser;

          final String? businessId = data['businessId'];
          if (businessId != null && businessId.isNotEmpty) {
            final businessDoc = await FirebaseFirestore.instance.collection('businesses').doc(businessId).get();
            if (businessDoc.exists) {
              final bName = businessDoc.data()?['businessName']?.toString();
              if (bName != null && bName.isNotEmpty) return bName;
            }
          }

          final String firstName = (data['firstName'] ?? '').toString();
          final String lastName = (data['lastName'] ?? '').toString();
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) return fullName;

          final email = (data['email'] ?? '').toString();
          if (email.isNotEmpty) return email;
        }
      }

      final businessQuery = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerId', isEqualTo: senderId)
          .limit(1)
          .get();

      if (businessQuery.docs.isNotEmpty) {
        final bName = businessQuery.docs.first.data()['businessName']?.toString();
        if (bName != null && bName.isNotEmpty) return bName;
      }
    } catch (_) {}
    return 'New message';
  }

  Future<void> _processNotification(String? senderName, String message, String senderId) async {
    if (!mounted) return;

    if (_activeUserId == null || FirebaseAuth.instance.currentUser?.uid != _activeUserId) return;
    if (senderId == widget.currentChatReceiverNotifier.value) return;

    // Resolve name first BEFORE showing (to avoid race conditions with OverlayEntry variable)
    String resolvedName = senderName ?? 'New message';
    bool isProbablyUid = !resolvedName.contains(' ') && resolvedName.length == 28;
    if (senderName == null || isProbablyUid) {
      resolvedName = await _resolveSenderName(senderId);
    }

    if (!mounted) return;
    _showBanner(resolvedName, message, senderId);
  }

  void _showBanner(String resolvedName, String message, String senderId) {
    _hideBanner();

    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => MessageNotificationBanner(
        senderName: resolvedName,
        message: message,
        onTap: () {
          _hideBanner();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                receiverName: resolvedName,
                receiverID: senderId,
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(_overlayEntry!);

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _hideBanner();
    });
  }
}