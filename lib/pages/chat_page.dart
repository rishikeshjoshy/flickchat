import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flikchat/componenets/my_textfield.dart';

// Import the new chat bubble widget
import '../componenets/chat_bubble.dart';
import '../services/auth/auth_service.dart';
import '../services/chat/chat_services.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _auth_service = AuthService();
  final FocusNode myFocusNode = FocusNode();

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    final senderID = _auth_service.getCurrentUser()!.uid;
    return _chatService.getMessages(senderID, widget.receiverID);
  }

  // _buildMessageItem method is now REMOVED
  // _formatTimestamp method is now REMOVED

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _chatService.sendMessage(widget.receiverID, text);

    _messageController.clear();
    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(milliseconds: 120));
    // ... your scroll logic ...
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Loading...'));
        }

        final docs = snapshot.data!.docs;
        final currentUserId = _auth_service.getCurrentUser()!.uid; // Get user ID once

        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            // Extract data inside the builder
            final doc = docs[index];
            final data = doc.data() ?? <String, dynamic>{};
            final text = (data['message'] as String?) ?? '';
            final senderId = (data['senderID'] as String?) ?? '';
            final timestamp = data['timestamp'];
            final isMine = senderId == currentUserId;

            // Use the new ChatBubble widget
            return ChatBubble(
              message: text,
              isMine: isMine,
              timestamp: timestamp,
              messageId: doc.id,
              userId: data["senderID"],
            );
          },
        );
      },
    );
  }

  Widget _buildUserInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: MyTextfield(
                hintText: "Message",
                ObscureText: false,
                controller: _messageController,
                focusNode: myFocusNode,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: sendMessage,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                backgroundColor: const Color(0xFF2FBF71),
                elevation: 3,
                shadowColor: const Color(0xFF2FBF71).withOpacity(0.25),
              ),
              child: const Text(
                'Send',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary
          ),),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildUserInput(),
        ],
      ),
    );
  }
}