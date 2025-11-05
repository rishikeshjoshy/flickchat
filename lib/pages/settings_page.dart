import 'package:flikchat/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Settings",
        style: TextStyle(
          color: Colors.green,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body:
      // Theme Switch Button
      Column(
        children: [
          Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(20)
          ),
          margin: EdgeInsets.all(25),
          padding:  EdgeInsets.all(25),

          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                //Dark Mode
                Text("Dark Mode",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),

                //Switch Toggle
                CupertinoSwitch(
                    value: Provider.of<ThemeProvider>(context , listen: false).isDarkMode,
                    onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme()
                ),
              ]
          ),
        ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(20)
            ),
            margin: EdgeInsets.only(left: 25, right: 25, top: 10),
            padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 25),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Blocked Icon
                //Icon(Icons.block_outlined,color: Colors.red,),

                //const SizedBox(width: 5,),

                // Blocked Users
                Text("Blocked Users",
                style: TextStyle(
                  color: Colors.red.shade500,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  ),
                ),

                // Button --> Navigates to Blocked User Page
                IconButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(
                        builder: (context) => BlockedUsersPage())),
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.red.shade500,
                    )
                )

              ],
            ),
          )
        ]
      ),


    );
  }
}
