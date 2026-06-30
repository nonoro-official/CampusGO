import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/services/message_service.dart';
import 'package:campusgo/services/business_service.dart';
import 'package:campusgo/models/business_model.dart';
import 'package:campusgo/views/home/chat_page.dart';
import 'package:campusgo/widgets/user_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusgo/providers/auth_provider.dart';
import 'package:campusgo/models/enums.dart';

class MessagesScreen extends ConsumerWidget {
  MessagesScreen({super.key});

  final MessageService _messageService = MessageService();
  final BusinessService _businessService = BusinessService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view messages')),
      );
    }

    final currentUserId = currentUser.uid;
    final isVendor =
        currentUser.role == Role.vendor || currentUser.role == Role.coVendor;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messageService.getUsersStream(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const Center(child: Text('Error loading users'));
          }
          if (!userSnapshot.hasData) {
            return const Center(child: Text('Loading users...'));
          }

          final allUsers = userSnapshot.data!;

          return StreamBuilder<List<BusinessModel>>(
            stream: _businessService.getAllBusinesses(),
            builder: (context, businessSnapshot) {
              if (businessSnapshot.hasError) {
                return const Center(child: Text('Error loading businesses'));
              }
              if (!businessSnapshot.hasData) {
                return const Center(child: Text('Loading businesses...'));
              }

              final businessesByOwnerId = {
                for (final business in businessSnapshot.data!)
                  business.ownerId: business,
              };

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messageService.getChatRoomsStream(currentUserId),
                builder: (context, chatRoomsSnapshot) {
                  if (chatRoomsSnapshot.hasError) {
                    return const Center(child: Text('Error loading chats'));
                  }
                  if (!chatRoomsSnapshot.hasData) {
                    return const Center(child: Text('Loading chats...'));
                  }

                  final chatRooms = chatRoomsSnapshot.data!;
                  final List<Map<String, dynamic>> sortedChatPartners = [];

                  for (var room in chatRooms) {
                    final participants =
                        List<String>.from(room['participants'] ?? []);
                    final contactInitiatedBy =
                        List<String>.from(room['contactInitiatedBy'] ?? []);

                    final otherId = participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => "");
                    if (otherId.isEmpty) continue;

                    final otherIsBusiness =
                        businessesByOwnerId.containsKey(otherId);

                    bool isValidPartner = false;
                    if (isVendor) {
                      if (otherIsBusiness) {
                        if (contactInitiatedBy.contains(currentUserId)) {
                          isValidPartner = true;
                        }
                      } else {
                        if (contactInitiatedBy.contains(otherId)) {
                          isValidPartner = true;
                        }
                      }
                    } else {
                      if (otherIsBusiness &&
                          contactInitiatedBy.contains(currentUserId)) {
                        isValidPartner = true;
                      }
                    }

                    if (isValidPartner) {
                      final user = allUsers.firstWhere(
                        (u) => (u['uid'] ?? '').toString() == otherId,
                        orElse: () => {},
                      );
                      if (user.isNotEmpty) {
                        sortedChatPartners.add({
                          'user': user,
                          'chatRoom': room,
                        });
                      }
                    }
                  }

                  if (sortedChatPartners.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }

                  return ListView.builder(
                    itemCount: sortedChatPartners.length,
                    itemBuilder: (context, index) {
                      final partnerData = sortedChatPartners[index];
                      final user = partnerData['user'] as Map<String, dynamic>;
                      final chatRoom = partnerData['chatRoom'] as Map<String, dynamic>;
                      final uid = user['uid'];

                      final lastSenderID = chatRoom['lastSenderID'];
                      final lastTimestamp = chatRoom['lastTimestamp'];
                      final lastSeen = chatRoom['lastSeen_$currentUserId'];

                      bool isUnread = false;

                      if (lastSenderID != null &&
                          lastSenderID != currentUserId &&
                          lastTimestamp != null) {
                        if (lastSeen == null) {
                          isUnread = true;
                        } else if (lastSeen is Timestamp &&
                            lastTimestamp is Timestamp) {
                          isUnread = lastTimestamp.compareTo(lastSeen) > 0;
                        }
                      }

                      final business = businessesByOwnerId[uid];

                      String displayName = 'Unknown';
                      String? avatarUrl;

                      if (business != null) {
                        displayName = business.businessName;
                        avatarUrl = business.imageUrl;
                      } else {
                        final firstName = user['firstName'] ?? '';
                        final lastName = user['lastName'] ?? '';
                        displayName = '$firstName $lastName'.trim().isNotEmpty
                            ? '$firstName $lastName'
                            : (user['email'] ?? 'User');
                        avatarUrl = user['profileImageUrl'] ?? user['imageUrl'];
                      }

                      return UserTile(
                        displayName: displayName,
                        avatarUrl: avatarUrl,
                        isOnline: user['isOnline'] ?? false,
                        lastSeen: _parseLastSeen(user),
                        isUnread: isUnread,
                        onTap: () {
                          _messageService.markAsRead(uid);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                receiverName: displayName,
                                receiverID: uid,
                                receiverImageUrl: avatarUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  DateTime? _parseLastSeen(Map<String, dynamic> user) {
    final dynamic ts = user['lastSeen'] ?? user['lastOnline'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }
}
