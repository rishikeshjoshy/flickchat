import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 5,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.all(20),
          child: Row(
            children: [

              // Icon
              Icon(Icons.person,
              size: 22,),

              const SizedBox(width: 5,),

              // Username
              Text(text,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w200
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
