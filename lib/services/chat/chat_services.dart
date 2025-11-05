import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package for database operations
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth package to access current user
import 'package:flikchat/models/message.dart'; // Message model to structure message data
import 'package:flikchat/services/auth/auth_service.dart'; // (Imported but not used in this file; kept if you plan to extend)

class ChatService { // ChatService class encapsulates messaging-related Firestore operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance used to read/write collections and documents
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instance used to get current user info

  // Get a stream of the main chat room document (for the emotion capsule)
  Stream<DocumentSnapshot> getChatRoomStream(String receiverID) {
    // Get current user ID
    final String currentUserID = _auth.currentUser!.uid;

    // Sort the UIDs to build the consistent chat room ID
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    final String chatRoomID = ids.join('_');

    // Return the stream
    return _firestore.collection('chat_rooms').doc(chatRoomID).snapshots();
  }

  // Update the user's emotion label in the chat room document
  Future<void> updateUserEmotion(String receiverID, String emotionLabel) async {
    // Get current user ID
    final String currentUserID = _auth.currentUser!.uid;

    // Get the chat room ID
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    final String chatRoomID = ids.join('_');

    // Get the document reference
    final docRef = _firestore.collection('chat_rooms').doc(chatRoomID);

    // Ensure the document exists before updating, or create it
    await docRef.set(
      {
        'emotions': {
          // Use dot notation to update only the current user's field
          currentUserID: emotionLabel,
        }
      },
      SetOptions(merge: true), // merge:true prevents overwriting the whole doc
    );
  }

  // Returns a stream of lists of user maps from the "Users" collection
  Stream<List<Map<String,dynamic>>> getUserStream(){ // Method to stream all user documents as a list of maps
    return _firestore.collection("Users").snapshots().map((snapshot){ // Listen to snapshots on the "Users" collection and map each QuerySnapshot
      return snapshot.docs.map((doc){ // For each DocumentSnapshot in the QuerySnapshot
        return doc.data(); // Return the raw document data (Map<String, dynamic>)
      }).toList(); // Convert the iterable of maps into a List<Map<String, dynamic>>
    }); // End of snapshots().map(...)
  } // End of getUserStream

  // Send a message to a specific receiverID
  Future<void> sendMessage(String receiverID, message) async { // Async method that sends a message; `message` can be String or any serializable value
    final String currentUserID = _auth.currentUser!.uid; // Get current user's UID from FirebaseAuth (non-null asserted)
    final String currentUserEmail = _auth.currentUser!.email!; // Get current user's email (non-null asserted)
    final Timestamp timestamp = Timestamp.now(); // Create a server-side-like timestamp using Firestore Timestamp.now()

    // Construct a Message model instance with required fields
    Message newMessage = Message( // Create a Message object using your model
        senderID: currentUserID, // Set senderID to the current user's UID
        senderEmail: currentUserEmail, // Set senderEmail to the current user's email
        receiverID: receiverID, // Set receiverID to the target user's UID
        message: message, // Set message payload (text or serialized content)
        timestamp: timestamp // Set timestamp when message is created locally
    ); // End of Message creation

    // Generate a deterministic chat room ID shared by both participants
    List<String> ids = [currentUserID, receiverID]; // Create a list containing both user IDs
    ids.sort(); // Sort the IDs so both users compute the same chatroomID regardless of order
    String chatroomID = ids.join('_'); // Join the sorted IDs with an underscore to form the chatroom document ID

    // Add the new message document under the chatroom's messages subcollection
    await _firestore // Await the Firestore write operation
        .collection("chat_rooms") // Top-level collection for chat rooms
        .doc(chatroomID) // Document representing this pair's chatroom (deterministic ID)
        .collection("messages") // Subcollection holding message documents for this chatroom
        .add(newMessage.toMap()); // Add a new message document using the Message model's toMap() representation
  } // End of sendMessage

  // Returns a stream of message QuerySnapshots for a chat between two users
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String userID, otherUserID){ // Method to stream messages between two users
    List<String> ids =[userID,otherUserID]; // Create a list with both user IDs
    ids.sort(); // Sort so both sides compute the same chatroom ID
    String chatroomID = ids.join('_'); // Join sorted IDs with underscore to form chatroomID

    return _firestore. // Return the Firestore query snapshot stream
    collection("chat_rooms") // Top-level chat_rooms collection
        .doc(chatroomID) // Document for the specific chatroom
        .collection("messages") // Messages subcollection inside that chatroom
        .orderBy("timestamp", descending: false) // Order messages by timestamp ascending (oldest first)
        .snapshots(); // Return real-time snapshots for the query so UI can listen to live updates
  } // End of getMessages



} // End of ChatService class