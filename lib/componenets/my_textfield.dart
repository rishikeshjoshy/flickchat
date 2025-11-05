import 'package:flutter/material.dart';
import 'package:flikchat/themes/light_mode.dart';

class MyTextfield extends StatelessWidget {
  final String hintText;
  final bool ObscureText;
  final TextEditingController controller;
  final FocusNode? focusNode;

  const MyTextfield({
    super.key,
    required this.hintText,
    required this.ObscureText,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        obscureText: ObscureText,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          fillColor: Theme.of(context).colorScheme.secondary,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
        ),
      ),
    );
  }
}
