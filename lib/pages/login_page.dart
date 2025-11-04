import 'package:flikchat/componenets/my_button.dart';
import 'package:flikchat/componenets/my_textfield.dart';
import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';


class LoginPage extends StatelessWidget {

  // Email & PW Text Editing Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmpwController = TextEditingController();

  // Toggle button onTap
  final void Function()? onTap;


  LoginPage({
    super.key,
    required this.onTap,
  });

  // Login Function
  void login(BuildContext context) async {
    // auth service
    final authService = AuthService();

    // try login
    try{
      await authService.signInWithEmailPassword(_emailController.text, _pwController.text);
    }
    // catch any errors
    catch(e){
      showDialog(context: context, builder: (context) => AlertDialog(
        title: Text(e.toString()),
      ));
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Icon(
                Icons.messenger_outline,
                size: 60,
            color: Colors.green,),
            
            const SizedBox(height: 25),
            // WELCOME BACK MESSAGE
            Text(
                "Welcome Back!!",
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),

            const SizedBox(height: 25,),
            // EMAIL TEXTFIELD
            MyTextfield(
              hintText:"Email",
              ObscureText: false,
              controller: _emailController,

            ),

            const SizedBox(height: 10,),
            // PASSWORD TEXTFIELD
            MyTextfield(
                hintText:"Password",
                ObscureText: true,
                controller: _pwController,
            ),

            const SizedBox(height: 20,),
            // LOGIN BTN
            MyButton(
              text: "Login",
              onTap: () => login(context),

            ),


            const SizedBox(height: 20,),
            GestureDetector(
              onTap: onTap,
              child: RichText(text: TextSpan(
                children: [
                  TextSpan(
                    text: "Not a member?",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16),
              ),
                  TextSpan(
                    text: " Register Now",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )
                  )
                ]
              )
              ),
            )
            // REGISTER NOW


        ],),
      ),
    );
  }
}
