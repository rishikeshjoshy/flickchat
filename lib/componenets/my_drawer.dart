import 'package:flikchat/pages/settings_page.dart';
import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  // Logout function
  void logout(){
    final _auth = AuthService();
    _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Icon(
                  Icons.messenger_outline,
                  color: Colors.green,
                  size: 45,
                ),
              ),
            ),

          // Home List Tile
          Padding(
              padding: const EdgeInsets.only(left: 25,top: 70),
              child: ListTile(
                title: Text(" H O M E",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20
                  ),
                ),
                leading: Icon(Icons.home, color: Theme.of(context).colorScheme.primary,),
                onTap: () {
                  // Pop the drawer
                  Navigator.pop(context);
                },
              ),
          ),

          // Setting List Tile
          Padding(padding: const EdgeInsets.only(left: 25, top: 25),
          child: ListTile(
            title: Text(" S E T T I N G S",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),),
            leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary,),
            onTap: () {

              // Pop the drawer
              Navigator.pop(context);

              // Navigate to the settings screen
              Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingsPage()));
            }

          ),
          ),
          Padding(padding: const EdgeInsets.only(left: 25, top: 350),
          child: ListTile(
            title: Text(" L O G O U T",
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),),
            leading: Icon(Icons.logout_outlined,color: Colors.red.shade300,),
            onTap: logout,
          ),
          )

        ],
      ),
    );
  }
}
