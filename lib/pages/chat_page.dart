// lib/pages/chat_page.dart (Your existing file, now modified)

import 'dart:async'; // --- NEW --- (For the Timer)
import 'dart:io'; // --- NEW --- (For File)
import 'dart:math'; // --- NEW --- (For Random interval)

import 'package:camera/camera.dart'; // --- NEW ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flikchat/componenets/my_textfield.dart';
import 'package:permission_handler/permission_handler.dart'; // --- NEW ---
import 'package:shared_preferences/shared_preferences.dart'; // --- NEW ---

// --- 1. IMPORT CLEANUP ---
// We only need the barrel file
import '../services/services.dart';
// import '../services/ml/ml_service.dart'; // This line was redundant and is REMOVED

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

  // --- NEW --- (All the new state variables for the feature)
  final MlService _mlService = MlService(); // Instance of our new ML service
  CameraController? _cameraController; // Controller for the camera
  Timer? _emotionTimer; // Timer for the random intervals
  bool _isEmotionFeatureEnabled = false; // User's preference from settings
  bool _isFeatureReady = false; // Tracks if camera and model are loaded
  String _otherUserEmotion = ''; // Holds the other user's emotion for the capsule
  // --- END NEW ---

  // --- NEW ---
  // We override initState to load all our new features
  @override
  void initState() {
    super.initState();
    // This function will handle all the async setup
    _initializeFeatures();
  }

  // --- NEW ---
  // A clean function to load everything the feature needs
  Future<void> _initializeFeatures() async {
    // 1. Load the user's setting from device storage
    final prefs = await SharedPreferences.getInstance();
    _isEmotionFeatureEnabled = prefs.getBool('isEmotionFeatureEnabled') ?? false;

    // 2. If the feature is disabled by the user, stop here.
    if (!_isEmotionFeatureEnabled) {
      print('Emotion feature is disabled by user.');
      return;
    }

    // 3. Load the TFLite Model
    await _mlService.loadModel();
    if (!_mlService.isModelLoaded) {
      print('Failed to load ML model, aborting feature.');
      return;
    }

    // 4. Initialize the Camera
    if (!await _initializeCamera()) {
      print('Failed to initialize camera, aborting feature.');
      return;
    }

    // 5. If everything is loaded, set the ready flag and start the timer
    setState(() {
      _isFeatureReady = true;
    });
    _startEmotionTimer();
  }

  // --- NEW ---
  // Handles camera permissions and initialization
  Future<bool> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      print('Camera permission denied');
      return false;
    }

    try {
      // Get available cameras and use the front one
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first, // Fallback to any camera
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Use low res for fast, silent snapshots
        enableAudio: false,
      );

      await _cameraController!.initialize();
      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  // --- NEW ---
  // Starts the random interval timer
  void _startEmotionTimer() {
    // Stop any existing timer
    _emotionTimer?.cancel();

    // Start a new periodic timer
    _emotionTimer = Timer.periodic(
      // --- DURATION ---
      // This creates a random interval between 30 and 60 seconds.
      // You can change these numbers.
      Duration(seconds: 30 + Random().nextInt(31)),
          (timer) {
        // This function will be called at every interval
        _captureAndAnalyze();
      },
    );
  }

  // --- NEW ---
  // This is the core function that runs at each interval
  Future<void> _captureAndAnalyze() async {
    // Guard clause: Don't run if feature is disabled or not ready
    if (!_isFeatureReady || _cameraController == null) {
      return;
    }

    try {
      // 1. Take the snapshot
      final snapshot = await _cameraController!.takePicture();

      // 2. Run inference
      final emotionLabel = await _mlService.runInference(snapshot.path);

      // 3. Delete the snapshot file (for privacy)
      try {
        File(snapshot.path).delete();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete snapshot: $e');
        }
      }

      // 4. If we got a result, send it to Firestore
      if (emotionLabel != null) {
        print('Analyzed emotion: $emotionLabel');
        await _chatService.updateUserEmotion(widget.receiverID, emotionLabel);
      }
    } catch (e) {
      print('Error during capture & analysis: $e');
    }
  }

  // --- MODIFIED --- (This function is from your code, unchanged)
  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    final senderID = _auth_service.getCurrentUser()!.uid;
    return _chatService.getMessages(senderID, widget.receiverID);
  }

  // --- MODIFIED --- (This function is from your code, unchanged)
  Widget _buildMessageItem(DocumentSnapshot<Map<String, dynamic>> doc) {
    // ... (Your existing message bubble code is perfect, no changes needed)
    final data = doc.data() ?? <String, dynamic>{};
    final text = (data['message'] as String?) ?? '';
    final senderId = (data['senderID'] as String?) ?? '';
    final timestamp = data['timestamp'];
    final currentUserId = _auth_service.getCurrentUser()!.uid;
    final isMine = senderId == currentUserId;
    final receiverGradient = const LinearGradient(
      colors: [Color(0xFF66E08A), Color(0xFF2FBF71)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final senderColor = const Color(0xFFF1F2F6);
    final receiverTextColor = Colors.white;
    final senderTextColor = Colors.black87;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.9;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 18 : 6),
      topRight: Radius.circular(isMine ? 6 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
              decoration: BoxDecoration(
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
                border:
                isMine ? Border.all(color: Colors.grey.shade300) : null,
              ),
              child: Column(
                crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMine ? senderTextColor : receiverTextColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp),
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
    );
  }

  // --- MODIFIED --- (This function is from your code, unchanged)
  static String _formatTimestamp(dynamic ts) {
    try {
      Timestamp t =
      ts is Timestamp ? ts : Timestamp.fromMillisecondsSinceEpoch(ts as int);
      final dt = t.toDate();
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    } catch (_) {
      return '';
    }
  }

  // --- MODIFIED --- (This function is from your code, unchanged)
  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _chatService.sendMessage(widget.receiverID, text);

    _messageController.clear();
    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(milliseconds: 120));
    // ... (Your scroll logic was commented out, I left it that way)
  }

  // --- MODIFIED --- (This function is from your code, unchanged)
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
        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildMessageItem(doc);
          },
        );
      },
    );
  }

  // --- MODIFIED --- (This function is from your code, unchanged)
  Widget _buildUserInput() {
    // ... (Your existing user input code is perfect, no changes needed)
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
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: sendMessage,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

  // --- 3. MODIFIED _buildEmotionCapsule ---
  // --- MODIFIED _buildEmotionCapsule with Debugging ---
  Widget _buildEmotionCapsule() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.getChatRoomStream(widget.receiverID),
      builder: (context, snapshot) {

        // --- 1. Is the StreamBuilder connecting? ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("CAPSULE: Stream is waiting...");
          return const SizedBox.shrink(); // Show nothing while loading
        }

        // --- 2. Did we get an error? ---
        if (snapshot.hasError) {
          print("CAPSULE ERROR: ${snapshot.error}");
          return const SizedBox.shrink();
        }

        // --- 3. Is the document empty? ---
        if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
          print("CAPSULE: No data or document doesn't exist. This is normal if it's a new chat.");
          return const SizedBox.shrink();
        }

        // --- 4. OK, we have a document. Let's check its contents. ---
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final emotions = data['emotions'] as Map<String, dynamic>?;

        if (emotions == null) {
          print("CAPSULE: Got document, but the 'emotions' map is missing.");
          return const SizedBox.shrink();
        }

        // --- 5. We have the 'emotions' map. Let's check for the receiver's key. ---
        // This is the most important part.
        final otherUserEmotion = emotions[widget.receiverID] as String?;

        if (otherUserEmotion == null || otherUserEmotion.isEmpty) {
          print("CAPSULE: Found 'emotions' map, but the key for receiver (${widget.receiverID}) is missing or empty.");
          return const SizedBox.shrink();
        }

        // --- 6. SUCCESS! ---
        print("CAPSULE: Success! Found emotion '$otherUserEmotion' for receiver ${widget.receiverID}.");
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                otherUserEmotion,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // --- NEW --- (Dispose all our new controllers)
    _emotionTimer?.cancel();
    _cameraController?.dispose();
    _mlService.dispose();
    // --- END NEW ---

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- 2. MODIFIED AppBar ---
        // The Row and capsule are removed, restoring the simple title.
        title: Text(
          widget.receiverEmail,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary, fontSize: 17),
        ),
        // --- END MODIFIED AppBar ---
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- 2. MOVED CAPSULE HERE ---
          // The capsule is now the first item in the body's Column
          _buildEmotionCapsule(),

          Expanded(child: _buildMessageList()),
          _buildUserInput(),
        ],
      ),
    );
  }
}