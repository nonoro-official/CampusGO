import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/pages/messages/chat_page.dart';
import '../../../providers/auth_provider.dart';

class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool dark;
  final bool showBack;
  final String? alignLogout;
  final bool dashboard;
  final bool center;
  final IconData? leftIcon;
  final VoidCallback? onLeftPressed;
  final IconData? rightIcon;
  final VoidCallback? onRightPressed;
  final String? messageReceiverId;
  final String? messageReceiverName;
  final String? messageReceiverImage;

  const TopBar({
    super.key,
    required this.title,
    this.dark = false,
    this.showBack = false,
    this.alignLogout,
    this.dashboard = false,
    this.center = false,
    this.leftIcon,
    this.onLeftPressed,
    this.rightIcon,
    this.onRightPressed,
    this.messageReceiverId,
    this.messageReceiverName,
    this.messageReceiverImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    final Color contentColor = dark ? Colors.white : primaryColor;

    final currentUser = FirebaseAuth.instance.currentUser;

    Future<void> handleLogout() async {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }

    Widget? leadingWidget;
    IconData? effectiveLeftIcon = leftIcon;
    VoidCallback? effectiveLeftAction = onLeftPressed;

    if (effectiveLeftIcon == null) {
      if (showBack) {
        effectiveLeftIcon = Icons.arrow_back;
        effectiveLeftAction = () => Navigator.pop(context);
      } else if (dashboard) {
        effectiveLeftIcon = Icons.chat_bubble_outline;
        effectiveLeftAction = () {
          if (messageReceiverId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  receiverName: messageReceiverName ?? "Chat",
                  receiverID: messageReceiverId!,
                  receiverImageUrl: messageReceiverImage,
                ),
              ),
            );
          } else {
            Navigator.pushNamed(context, '/messages');
          }
        };
      }
    }

    // UNREAD INDICATOR
    if (effectiveLeftIcon != null && dashboard && currentUser != null) {
      leadingWidget = StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          bool hasUnread = false;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              final lastSenderID = data['lastSenderID'];
              final lastTimestamp = data['lastTimestamp'];
              final lastSeen = data['lastSeen_${currentUser.uid}'];

              if (lastSenderID != currentUser.uid &&
                  lastTimestamp != null) {
                if (lastSeen == null) {
                  hasUnread = true;
                  break;
                } else if (lastSeen is Timestamp &&
                    lastTimestamp is Timestamp &&
                    lastTimestamp.compareTo(lastSeen) > 0) {
                  hasUnread = true;
                  break;
                }
              }
            }
          }

          return Stack(
            children: [
              IconButton(
                icon: Icon(effectiveLeftIcon),
                color: contentColor,
                onPressed: effectiveLeftAction,
              ),

              if (hasUnread)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else if (effectiveLeftIcon != null) {
      leadingWidget = IconButton(
        icon: Icon(effectiveLeftIcon),
        color: contentColor,
        onPressed: effectiveLeftAction,
      );
    }

    IconData? effectiveRightIcon = rightIcon;
    VoidCallback? effectiveRightAction = onRightPressed;

    if (effectiveRightIcon == null && dashboard) {
      effectiveRightIcon = Icons.person_outline;
      effectiveRightAction = () {
        Navigator.pushNamed(context, '/menu');
      };
    }

    if (alignLogout.toString().toUpperCase() == "R") {
      effectiveRightIcon = Icons.logout;
      effectiveRightAction = handleLogout;
    } else if (alignLogout.toString().toUpperCase() == "L") {
      effectiveLeftIcon = Icons.logout;
      effectiveLeftAction = handleLogout;
    }

    return AppBar(
      backgroundColor: dark
          ? primaryColor
          : (Theme.of(context).appBarTheme.backgroundColor ?? Colors.white),
      elevation: 0,
      centerTitle: center || dashboard,
      leading: leadingWidget,
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(color: contentColor),
      ),
      actions: [
        if (effectiveRightIcon != null)
          IconButton(
            icon: Icon(effectiveRightIcon, size: 28),
            color: contentColor,
            onPressed: effectiveRightAction,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}