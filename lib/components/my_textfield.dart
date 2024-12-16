import "package:flutter/material.dart";

class MyTextField extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required bool filled,
    required this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
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
          if (value == null || value.isEmpty) {
            return 'Please enter some details.';
          }
          return null;
        },
      ),
    );
  }
}
