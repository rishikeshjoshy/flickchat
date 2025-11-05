import 'package:flikchat/componenets/user_tile.dart';
import 'package:flikchat/services/auth/auth_service.dart';
import 'package:flikchat/services/chat/chat_services.dart';
import 'package:flutter/material.dart';

class BlockedUsersPage extends StatelessWidget {
  BlockedUsersPage({super.key});

  // get chat & auth service
  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();

  // unblock box
  void _unBlockBox(BuildContext context, String userId) async {
  showDialog(context: context, builder: (context) => AlertDialog(
    title: const Text("Unblock User"),
    content: const Text("Are you sure you want to unblock this user?"),
    actions: [

      // Cancel Button
      TextButton(onPressed: () => Navigator.pop(context),
       child: Text(("Cancel"))),

      // Unblock Button
      TextButton(
          onPressed: () {
            Navigator.pop(context);
            chatService.unBlockUser(userId);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("User has been unblocked successfully!",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
            )
            )
            );
          },
       child: Text(("Unblock")))
    ],
  ));
  }

  @override
  Widget build(BuildContext context) {

    String userId = authService.getCurrentUser()!.uid;

    // UI
    return Scaffold(
      appBar:AppBar(
        title: Text("Blocked Users",
          style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 24,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(stream: chatService.getBlockedUsersStream(userId),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {

        // Error
        if(snapshot.hasError){
            return const Center(
                child:
                  Text("Error Loading."),
            );
          }

        // Loading
        if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
        }

        final blockedUsers = snapshot.data?? [];

        // No Users upon checking
        if(blockedUsers.isEmpty){
          return const Center(
            child: Text("No Blocked Users.",
              style: TextStyle(
                  fontSize: 32,
                  color: Colors.green,
                  fontWeight: FontWeight.bold
              ),
            ),
          );
        }

        // Load Complete
        return ListView.builder(itemCount: blockedUsers.length,
            itemBuilder: (context, index){
          final user = blockedUsers[index];
          return UserTile(
              text: user["email"],
              onTap: () => _unBlockBox(context, user["uid"])
          );
        });

        },
      ),
    );
  }
}
