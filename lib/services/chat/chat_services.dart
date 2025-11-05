import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package for database operations
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth package to access current user
import 'package:flikchat/models/message.dart'; // Message model to structure message data
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/change_notifier.dart';

class ChatService extends ChangeNotifier { // ChatService class encapsulates messaging-related Firestore operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance used to read/write collections and documents
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Get all users
  Stream<List<Map<String,dynamic>>> getUserStream(){ // Method to stream all user documents as a list of maps
    return _firestore.collection("Users").snapshots().map((snapshot){ // Listen to snapshots on the "Users" collection and map each QuerySnapshot
      return snapshot.docs.map((doc){ // For each DocumentSnapshot in the QuerySnapshot
        return doc.data(); // Return the raw document data (Map<String, dynamic>)
      }).toList(); // Convert the iterable of maps into a List<Map<String, dynamic>>
    }); // End of snapshots().map(...)
  } // End of getUserStream

  // Get all users except blocked users
  Stream<List<Map<String,dynamic>>> getUsersStreamExcludingBlocked(){
    final currentUser = _auth.currentUser;

    return _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async{

          // Get Blocked User
          final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

          // Get All User Ids
          final userSnapshot = await _firestore.collection('Users').get();

          // Return as a stream list
          return userSnapshot
              .docs.where((doc) => doc.data()['email'] != currentUser.email && !blockedUserIds.contains(doc.id))
              .map((doc) => doc.data())
              .toList();
          
      }
    );
  }

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

  // Report User
  Future<void> reportUser(String messageId, String userId) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedBy':currentUser!.uid,
      'messageId':messageId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('Reports').add(report);  // Making a new collection called reports and storing all the data collected from the map created above 'report'

  }

  // Block User
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(userId)
        .set({});
    notifyListeners();

  }

  // Unblock User
  Future<void> unBlockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;

    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  // Get blocked User(s) Stream
  Stream<List<Map<String,dynamic>>> getBlockedUsersStream(userId){
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async{
          // Getting the list of blocked user IDs
          final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

          final userDocs = await Future.wait(
            blockedUserIds.map((id) => _firestore.collection('Users').doc(id).get())
          );

          // Returning as a List
          return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });

  }

} // End of ChatService class