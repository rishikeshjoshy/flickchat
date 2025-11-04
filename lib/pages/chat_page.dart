import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore types and query/timestamp helpers
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:flikchat/componenets/my_textfield.dart'; // Custom text field widget used for message input

import '../services/auth/auth_service.dart'; // AuthService to get current user info
import '../services/chat/chat_services.dart'; // ChatService to send and receive messages

class ChatPage extends StatefulWidget { // Stateful widget representing a chat screen
  final String receiverEmail; // Receiver's email to display in the AppBar
  final String receiverID; // Receiver's UID used to compute the chat room id

  const ChatPage({ // Constructor for ChatPage
    super.key, // Pass the key to the StatefulWidget base class
    required this.receiverEmail, // Require receiverEmail when constructing ChatPage
    required this.receiverID, // Require receiverID when constructing ChatPage
  }); // End constructor

  @override // Override annotation for createState
  State<ChatPage> createState() => _ChatPageState(); // Create the mutable state for this widget
} // End ChatPage

class _ChatPageState extends State<ChatPage> { // State class for ChatPage
  final TextEditingController _messageController = TextEditingController(); // Controller for the message input field
  final ScrollController _scrollController = ScrollController(); // Controller to programmatically scroll the messages list
  final ChatService _chatService = ChatService(); // Instance of ChatService for DB operations
  final AuthService _auth_service = AuthService(); // Instance of AuthService to access current user (note: variable name preserved)

  // Build stream of messages for this chat (ChatService computes chatroom id internally)
  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() { // Method to get the message stream
    final senderID = _auth_service.getCurrentUser()!.uid; // Get current user's UID from AuthService
    return _chatService.getMessages(senderID, widget.receiverID); // Return the Firestore stream for messages between sender and receiver
  } // End _messagesStream

  // Single message bubble builder
  Widget _buildMessageItem(DocumentSnapshot<Map<String, dynamic>> doc) { // Method to build a single message UI from a document
    final data = doc.data() ?? <String, dynamic>{}; // Extract document data as a Map or empty map if null

    // IMPORTANT: Use the same key name used when saving the message in ChatService / Message model
    final text = (data['message'] as String?) ?? ''; // Extract the message text from the document
    final senderId = (data['senderID'] as String?) ?? ''; // Extract the senderID field from the document (must match stored key)
    final timestamp = data['timestamp']; // Extract the timestamp field (may be a Timestamp or int)
    final currentUserId = _auth_service.getCurrentUser()!.uid; // Get the currently signed in user's UID
    final isMine = senderId == currentUserId; // Determine whether this message was sent by the current user

    // receiver bubble color (green) and sender bubble color (light grey)
    final receiverGradient = const LinearGradient( // Gradient for receiver bubble
      colors: [Color(0xFF66E08A), Color(0xFF2FBF71)], // Gradient color stops for green bubble
      begin: Alignment.topLeft, // Gradient begin alignment
      end: Alignment.bottomRight, // Gradient end alignment
    ); // End receiverGradient
    final senderColor = const Color(0xFFF1F2F6); // Solid color for sender (current user) bubble
    final receiverTextColor = Colors.white; // Text color for receiver bubble (contrast on green)
    final senderTextColor = Colors.black87; // Text color for sender bubble (dark on light grey)

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.9; // Limit the bubble width to 74% of screen width

    // Asymmetric border radii so left and right bubbles look different
    final borderRadius = BorderRadius.only( // Border radius to create distinct shapes for left/right bubbles
      topLeft: Radius.circular(isMine ? 18 : 6), // Top-left radius depends on owner
      topRight: Radius.circular(isMine ? 6 : 18), // Top-right radius depends on owner
      bottomLeft: const Radius.circular(18), // Bottom-left fixed radius
      bottomRight: const Radius.circular(18), // Bottom-right fixed radius
    ); // End borderRadius

    return Padding( // Outer padding around each message bubble
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0), // Vertical and horizontal padding
      child: Row( // Row to align bubble left or right
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start, // Align to end if mine, start if receiver
        crossAxisAlignment: CrossAxisAlignment.end, // Align children to the bottom
        children: [ // Children of the Row
          ConstrainedBox( // Constrain the maximum width of the bubble
            constraints: BoxConstraints(maxWidth: maxBubbleWidth), // Apply max width constraint
            child: Container( // The bubble container
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0), // Inner padding inside the bubble
              decoration: BoxDecoration( // Decoration for the bubble
                // receiver (not mine) gets green gradient; mine gets light grey color
                gradient: isMine ? null : receiverGradient, // Apply gradient for receiver bubbles
                color: isMine ? senderColor : const Color(0xFF2FBF71), // Apply solid color for sender or fallback green for receiver
                borderRadius: borderRadius, // Apply the asymmetric border radius
                boxShadow: [ // Subtle shadow for elevation
                  BoxShadow( // Shadow definition
                    color: Colors.black.withOpacity(isMine ? 0.04 : 0.12), // Shadow opacity varies by owner
                    blurRadius: isMine ? 4 : 8, // Blur radius varies by owner
                    offset: const Offset(0, 3), // Shadow offset
                  ), // End BoxShadow
                ], // End boxShadow list
                border: isMine ? Border.all(color: Colors.grey.shade300) : null, // Thin border for sender bubbles
              ), // End BoxDecoration
              child: Column( // Column inside bubble for message text and timestamp
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start, // Align text and time appropriately
                mainAxisSize: MainAxisSize.min, // Shrink column to fit content
                children: [ // Children of the column
                  Text( // Message text widget
                    text, // The message string to display
                    style: TextStyle( // Text style for message
                      color: isMine ? senderTextColor : receiverTextColor, // Choose text color based on owner
                      fontSize: 15, // Font size for message text
                      height: 1.35, // Line height multiplier for readability
                    ), // End TextStyle
                  ), // End Text
                  const SizedBox(height: 6), // Spacing between message and timestamp
                  if (timestamp != null) // Only show timestamp when available
                    Text( // Timestamp text widget
                      _formatTimestamp(timestamp), // Formatted timestamp string (HH:mm)
                      style: TextStyle( // Style for timestamp
                        color: isMine ? Colors.black45 : Colors.white70, // Timestamp color based on owner bubble
                        fontSize: 10, // Smaller font for timestamp
                      ), // End TextStyle for timestamp
                    ), // End timestamp Text
                ], // End children for Column
              ), // End Column
            ), // End Container
          ), // End ConstrainedBox
        ], // End Row children
      ), // End Row
    ); // End Padding and return widget
  } // End _buildMessageItem

  // Format timestamp (accepts Timestamp or milliseconds int)
  static String _formatTimestamp(dynamic ts) { // Helper to format Firestore Timestamp or milliseconds into HH:mm
    try { // Attempt to parse ts
      Timestamp t = ts is Timestamp ? ts : Timestamp.fromMillisecondsSinceEpoch(ts as int); // Convert to Timestamp if needed
      final dt = t.toDate(); // Convert Timestamp to DateTime
      final hours = dt.hour.toString().padLeft(2, '0'); // Pad hour with leading zero
      final minutes = dt.minute.toString().padLeft(2, '0'); // Pad minute with leading zero
      return '$hours:$minutes'; // Return formatted time string
    } catch (_) { // If parsing fails
      return ''; // Return empty string on failure
    } // End try/catch
  } // End _formatTimestamp

  // Send message via ChatService and scroll to newest
  Future<void> sendMessage() async { // Method to send the typed message
    final text = _messageController.text.trim(); // Read and trim the input text
    if (text.isEmpty) return; // Return early if there is no text to send

    await _chatService.sendMessage(widget.receiverID, text); // Call ChatService to write the message document to Firestore

    _messageController.clear(); // Clear the input field after sending
    FocusScope.of(context).unfocus(); // Dismiss the keyboard after sending

    // small delay for stream to update then scroll to bottom (newest)
    await Future.delayed(const Duration(milliseconds: 120)); // Small delay to let Firestore stream update
    // if (_scroll_controller_has_clients()) { // Check if the scroll controller is attached to any Scrollable
    //   // when using reverse: true, scroll to minScrollExtent to show newest
    //   _scrollController.animateTo( // Animate the list to the bottom (newest) position
    //     _scrollController.position.minScrollExtent, // Target scroll position when reverse is true
    //     duration: const Duration(milliseconds: 220), // Duration of animation
    //     curve: Curves.easeOut, // Animation curve
    //   ); // End animateTo
    // } // End if
  } // End sendMessage

  // Build the message list with StreamBuilder
  Widget _buildMessageList() { // Method returning the message list widget
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>( // StreamBuilder to listen to Firestore messages stream
      stream: _messagesStream(), // Attach the messages stream for this chat
      builder: (context, snapshot) { // Builder callback with snapshot
        if (snapshot.hasError) { // If stream produced an error
          return Center(child: Text('Error ${snapshot.error}')); // Show error text in center
        } // End if
        if (snapshot.connectionState == ConnectionState.waiting) { // While waiting for initial data
          return const Center(child: Text('Loading...')); // Show loading indicator text
        } // End if

        final docs = snapshot.data!.docs; // Get the list of document snapshots from the QuerySnapshot

        // reverse:true so newest messages appear at the bottom of the visible list
        return ListView.builder( // Build a performant scrollable list
          controller: _scrollController, // Attach the scroll controller
          reverse: false, // Reverse so newest messages show at bottom when scrolled to top
          padding: const EdgeInsets.symmetric(vertical: 12), // Padding around list
          itemCount: docs.length, // Number of items to build
          itemBuilder: (context, index) { // Item builder callback
            final doc = docs[index]; // Get document at this index
            return _buildMessageItem(doc); // Build and return message bubble widget for this document
          }, // End itemBuilder
        ); // End ListView.builder
      }, // End builder
    ); // End StreamBuilder return
  } // End _buildMessageList

  // Input row with send button
  Widget _buildUserInput() { // Method to build the input row with text field and send button
    return SafeArea( // SafeArea to avoid system intrusions like notches and nav bars
      child: Container( // Container wrapping the input controls
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), // Inner padding for the input area
        color: Theme.of(context).colorScheme.surface,// Background color for the input area

        child: Row( // Row containing the text field and send button
          children: [ // Children of the Row
            Expanded(// Expanded to let the text field take available horizontal space
              child: MyTextfield(// Custom text field widget for message input
                hintText: "Message", // Placeholder text
                ObscureText: false, // Not obscuring input for chat
                controller: _messageController, // Attach controller to read/write the text
              ), // End MyTextfield
            ), // End Expanded
            const SizedBox(width: 8), // Horizontal gap between text field and button
            ElevatedButton( // Send button
              onPressed: sendMessage, // Call sendMessage when pressed
              style: ElevatedButton.styleFrom( // Styling for the button
                shape: RoundedRectangleBorder( // Rounded rectangle shape
                  borderRadius: BorderRadius.circular(10), // Corner radius for the button
                ), // End shape
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Inner padding for the button
                backgroundColor: const Color(0xFF2FBF71), // Button background color (green)
                elevation: 3, // Elevation for shadow
                shadowColor: const Color(0xFF2FBF71).withOpacity(0.25), // Button shadow color with opacity
              ), // End styleFrom
              child: const Text( // Button label
                'Send', // Label text
                style: TextStyle(fontSize: 14, color: Colors.white), // Label text style
              ), // End Text
            ), // End ElevatedButton
          ], // End Row children
        ), // End Row
      ), // End Container
    ); // End SafeArea
  } // End _buildUserInput

  @override // Override annotation for dispose
  void dispose() { // Dispose lifecycle method
    _messageController.dispose(); // Dispose message controller to free resources
    _scrollController.dispose(); // Dispose scroll controller to free resources
    super.dispose(); // Call superclass dispose
  } // End dispose

  @override // Override annotation for build
  Widget build(BuildContext context) { // Build method for the widget tree
    return Scaffold( // Scaffold provides basic visual layout structure
      appBar: AppBar( // Top app bar for the chat screen
        title: Text(widget.receiverEmail,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary
        ),), // Show receiver's email as the title
        backgroundColor: Theme.of(context).colorScheme.surface, // AppBar background color
        foregroundColor: Colors.black87, // AppBar text/icon color
        elevation: 1, // Slight elevation for app bar shadow
      ), // End AppBar
      body: Column( // Column layout to place messages list above input row
        children: [ // Children of the Column
          Expanded(child: _buildMessageList()), // Expanded widget for message list to take remaining space
          _buildUserInput(), // Input row for composing messages
        ], // End children
      ), // End Column
    ); // End Scaffold
  } // End build
} // End _ChatPageState