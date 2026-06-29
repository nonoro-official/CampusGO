import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unimart/components/chat_bubble.dart';
import 'package:unimart/services/auth_service.dart';
import 'package:unimart/services/message_service.dart';
import 'package:unimart/utils/online_utils.dart';
import 'package:unimart/main.dart' show currentChatReceiverNotifier;

class ChatPage extends StatefulWidget {
  final String receiverName;
  final String receiverID;
  final String? receiverImageUrl;

  const ChatPage({
    super.key,
    required this.receiverName,
    required this.receiverID,
    this.receiverImageUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();

    // Set the current chat receiver immediately so notification banner knows we're in this chat
    currentChatReceiverNotifier.value = widget.receiverID;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageService.markAsRead(widget.receiverID);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    // Clear the current chat receiver when leaving chat
    if (currentChatReceiverNotifier.value == widget.receiverID) {
      currentChatReceiverNotifier.value = null;
    }

    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Clear text immediately to prevent multiple sends/spam
    _messageController.clear();

    // 2. Keep focus for quick follow-up messages
    _focusNode.requestFocus();

    // 3. UI feedback
    _scheduleScrollToBottom();

    // 4. Send message (Optimized batch write in service)
    _messageService.sendMessage(
      widget.receiverID,
      text,
    ).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverID)
              .snapshots(),
          builder: (context, snapshot) {
            String? currentImageUrl = widget.receiverImageUrl;
            bool isOnline = false;
            dynamic lastSeen;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              currentImageUrl = data?['imageUrl'] ?? currentImageUrl;
              isOnline = isUserActuallyOnline(data);
              lastSeen = data?['lastSeen'];
            }

            final hasImage =
                currentImageUrl != null && currentImageUrl.isNotEmpty;

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: hasImage
                      ? NetworkImage(currentImageUrl)
                      : null,
                  child: hasImage
                      ? null
                      : Text(
                    widget.receiverName.isNotEmpty
                        ? widget.receiverName[0]
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isOnline)
                        const Text(
                          'Online',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        )
                      else
                        Text(
                          lastSeen != null
                              ? 'Last seen ${formatLastSeen(lastSeen)}'
                              : 'Offline',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final senderID = _authService.currentUser?.uid;
    if (senderID == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<QuerySnapshot>(
      stream: _messageService.getMessages(senderID, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading messages'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Handle side-effects (scrolling and marking read) after the build phase
        if (docs.length != _lastMessageCount) {
          _lastMessageCount = docs.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
            // Only mark as read if the last message is from the other person
            if (docs.isNotEmpty) {
              final lastDoc = docs.last.data() as Map<String, dynamic>;
              if (lastDoc['senderID'] == widget.receiverID && lastDoc['isSeen'] != true) {
                _messageService.markAsRead(widget.receiverID);
              }
            }
          });
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildMessageItem(docs[index]),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final message = data?['message']?.toString() ?? '';
    final timestamp = data?['timestamp'];
    final DateTime? sentAt = timestamp is Timestamp ? timestamp.toDate() : null;
    final bool isSeen = data?['isSeen'] ?? false;

    bool isCurrentUser = data!['senderID'] == _authService.currentUser!.uid;
    var alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ChatBubble(
              message: message,
              isCurrentUser: isCurrentUser,
              sentAt: sentAt,
              isSeen: isSeen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0, left: 8, right: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              final isNotEmpty = value.text.trim().isNotEmpty;
              return IconButton(
                iconSize: 28,
                icon: Icon(
                  Icons.send,
                  color: isNotEmpty ? Colors.red : Colors.grey,
                ),
                onPressed: isNotEmpty ? sendMessage : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
