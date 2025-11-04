import 'package:firebase_auth/firebase_auth.dart';
import 'package:flikchat/services/auth/auth_service.dart';
import 'package:flikchat/services/chat/chat_services.dart';
import 'package:flutter/material.dart';

import '../componenets/my_drawer.dart';
import '../componenets/user_tile.dart';
import 'chat_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Chat & Auth Service
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // void logout(){
  //   // Get Auth Service
  //   final _auth = FirebaseAuth.instance;
  //   _auth.signOut();
  //
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // actions: [
        //   // logout button
        //   IconButton(onPressed: logout, icon: Icon(Icons.logout_outlined))
        // ],
        title: Text("Home",
          style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 24),
        ),
      ),
      drawer: MyDrawer(),
      body: _buildUserList(),
    );
  }
  Widget _buildUserList(){
    return StreamBuilder(
      builder: (context,snapshot){
        // error
        if(snapshot.hasError){
          return const Text("Error!");
        }
        // loading
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Text("Loading..");
        }

        // list view
        return ListView(
          children: snapshot.data!.map<Widget>((userData) => _buildUserListItem(userData,context))
              .toList(),
        );

      },
      stream: _chatService.getUserStream(),
    );
  }

  // Build Individual List Tile for User
  Widget _buildUserListItem(Map<String,dynamic>userData , BuildContext context) {

    // Display all user except
    if(userData["email"] != _authService.getCurrentUser()!.email){
      return UserTile(
          text: userData["email"],
          onTap: (){
            // Tapped on a user?? -> go to chat page
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverEmail: userData["email"],
                      receiverID: userData["uid"],
                    )
                )
            );
          }
      );
    } else {
      return Container(

      );
    }


  }

}
