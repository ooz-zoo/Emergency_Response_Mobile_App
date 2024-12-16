import "package:flutter/material.dart";

class MyPasswordTextField extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int? maxLength;

  const MyPasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required bool filled,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLength: 10,
        decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            fillColor: Colors.white, //Colors.blue,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.black)),
        validator: (value) {
          final passwordRegExp = RegExp(
              r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          } else if (!passwordRegExp.hasMatch(value)) {
            return 'Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character.';
          }
          return null;
        },
      ),
    );
  }
}
