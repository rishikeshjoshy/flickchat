import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flikchat/services/chat/chat_services.dart';
import 'package:flutter/material.dart';

// A helper function to format timestamps (moved from the original class)
String _formatTimestamp(dynamic ts) {
  try {
    Timestamp t = ts is Timestamp ? ts : Timestamp.fromMillisecondsSinceEpoch(ts as int);
    final dt = t.toDate();
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  } catch (_) {
    return '';
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMine;
  final dynamic timestamp;
  final String messageId;
  final String userId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.timestamp, required this.messageId, required this.userId,
  });

  // Show Options
  void _showOptions(BuildContext context, String messageId, String userId){
    showModalBottomSheet(context: context, builder: (context){
      return SafeArea(child: Wrap(children: [

        // report button
        ListTile(
          leading: const Icon(Icons.flag, color: Colors.red),
          title: const Text('Report'),
          onTap: () {
            Navigator.pop(context);
            _reportContent(context, messageId, userId);
          },
        ),
        // block button
        ListTile(
          leading: const Icon(Icons.block_outlined, color: Colors.red,),
          title: const Text('Block'),
          onTap: () {
            _blockUser(context, userId);
          },
        ),
        // cancel button
        ListTile(
          leading: const Icon(Icons.cancel_outlined, color: Colors.amber,),
          title: const Text('Cancel'),
          onTap: () {
              Navigator.pop(context);
          },
        )

          ],
        )
      );
    }
    );
  }

  // Report Message
  void _reportContent(BuildContext context , String messageId , String userId){
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Report Message"),
      content: const Text("Are you sure you want to report this text?",
        style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Cancel button
        TextButton(onPressed: (){
          Navigator.pop(context);

        }, child: Text("Cancel")),
        
        // Report button
        TextButton(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reported the user successfully",style: TextStyle(color: Colors.green),)));
          ChatService().reportUser(messageId, userId);
          Navigator.pop(context);
        },
            child: Text("Report"))
      ],
    ));
  }
  // Block User
  void _blockUser(BuildContext context , String userId){
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Block User"),
      content: const Text("Are you sure you want to block this user?",
        style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(onPressed: (){
          Navigator.pop(context);
        },
            child: Text("Cancel")),

        // Block Button
        TextButton(onPressed: (){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blocked the user successfully",style: TextStyle(color: Colors.green),)));
          ChatService().blockUser(userId);
          Navigator.pop(context);
        },
            child: Text("Block this user")),
      ],
    ));
  }


  @override
  Widget build(BuildContext context) {
    // receiver bubble color (green) and sender bubble color (light grey)
    final receiverGradient = const LinearGradient(
      colors: [Color(0xFF66E08A), Color(0xFF2FBF71)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final senderColor = const Color(0xFFF1F2F6);
    final receiverTextColor = Colors.white;
    final senderTextColor = Colors.black87;

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.9;

    // Asymmetric border radii so left and right bubbles look different
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 18 : 6),
      topRight: Radius.circular(isMine ? 6 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    return GestureDetector(
      onLongPress: (){
        if(!isMine){
          _showOptions(context, messageId, userId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                decoration: BoxDecoration(
                  // receiver (not mine) gets green gradient; mine gets light grey color
                  gradient: isMine ? null : receiverGradient,
                  color: isMine ? senderColor : const Color(0xFF2FBF71),
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isMine ? 0.04 : 0.12),
                      blurRadius: isMine ? 4 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isMine ? Border.all(color: Colors.grey.shade300) : null,
                ),
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message, // Use the 'message' property
                      style: TextStyle(
                        color: isMine ? senderTextColor : receiverTextColor,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (timestamp != null) // Use the 'timestamp' property
                      Text(
                        _formatTimestamp(timestamp), // Use the top-level helper
                        style: TextStyle(
                          color: isMine ? Colors.black45 : Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}