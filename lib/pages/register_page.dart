
import 'package:flikchat/componenets/my_button.dart';
import 'package:flikchat/componenets/my_textfield.dart';
import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';

class RegisterPage extends StatelessWidget {

  // Controllers for pw & email
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmpwController = TextEditingController();

  // toggle function for onTap
  final void Function() onTap;

  RegisterPage({
    super.key,
    required this.onTap,
  });

  // Register Function
  void register(BuildContext context){
    // get auth service
    final _auth = AuthService();


    // If Password matches --> create user
    if(_pwController.text == _confirmpwController.text){
    try{
        _auth.signUpWithEmailPassword(_emailController.text, _pwController.text);
      }
      catch(e){
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(e.toString()),
            ),
        );
      }
    }
    // If Password doesn't match --> Show Error Message
    showDialog(
      barrierLabel: "Error",
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Password don't match! Re-enter",
          style: TextStyle(fontSize: 16),),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
                Icons.messenger_outline,
                size: 60,
                color: Colors.green,),

            const SizedBox(height: 25,),

            // Register Now message
            Text(
              "Welcome to Flickchat",
             style: TextStyle(
               color: Colors.green,
               fontSize: 20
             ),),

            const SizedBox(height: 25,),
            // EMAIL TEXTFIELD
            MyTextfield(
                hintText: "Email",
                ObscureText: false,
                controller: _emailController
            ),

            const SizedBox(height: 10,),
            // PW TEXTFIELD
            MyTextfield(
                hintText: "Password",
                ObscureText: true,
                controller: _pwController
            ),

            const SizedBox(height: 10,),
            // RE-ENTER PW
            MyTextfield(
                hintText: "Confirm Password",
                ObscureText: true,
                controller: _confirmpwController),

            const SizedBox(height: 10,),
            // Requirement Text
            Text("Requirements : 1 Uppercase, 1 Lowercase, 1 Number",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),),

            const SizedBox(height: 20,),
            // Register Button
            MyButton(
                text: "Register",
                onTap: () => register(context),
            ),
            const SizedBox(height: 20,),
            // Already have an account? Text
            Center(
              child: GestureDetector(
                onTap: onTap,
                child: RichText(text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Already have an account?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: " Login now",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )
                    )
                  ]
                )),
              ),
            )


          ],
        ),
      )
    );
  }
}
