import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:journeyai/components/my_button.dart';
import 'package:journeyai/components/square_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import '../user_auth/firebase_auth_implementation/firebase_auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // GlobalKey for form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Email validation logic
  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validation logic
  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password cannot be empty';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method to check for emergency contacts in Firestore
  Future<void> _checkEmergencyContacts(User user) async {
    // Reference the Firestore collection for the current user's emergency contacts
    CollectionReference emergencyContacts = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // Current user's document
        .collection('emergencyContacts');

    // Get the documents from the sub-collection
    QuerySnapshot snapshot = await emergencyContacts.get();

    if (snapshot.docs.isNotEmpty) {
      print('Emergency contacts found');
      Navigator.pushNamed(context, "/e_dashboard");
    } else {
      print('No emergency contacts found');
      Navigator.pushNamed(context, "/empty");
    }
  }

  // Sign in method
  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      // Validate the form
      String email = _emailController.text;
      String password = _passwordController.text;

      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (user != null) {
        print("User is logged in");
        Navigator.pushNamed(context, "/main_home"); // Route to MainHome
      } else {
        print("User not logged in");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed. Please try again.")),
        );
      }
    }
  }

  // Forgot password handler
  void _forgotPassword() async {
    String email = _emailController.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Password"),
        content: TextFormField(
          controller: _emailController,
          decoration: InputDecoration(hintText: "Enter your email"),
          validator: (value) => _validateEmail(value!),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_emailController.text.isNotEmpty) {
                try {
                  await _auth.sendPasswordResetEmail(_emailController.text);
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password reset email sent!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  // Password visibility
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB2BEC3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  SquareTile(imagePath: "lib/images/logos/logo3.png"),
                  const SizedBox(height: 20),
                  // Welcome back text
                  const Text(
                    "Welcome back",
                    style: TextStyle(
                      color: Color(0xFFD63031),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        fillColor: Colors.grey,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                      validator: (value) => _validateEmail(value!),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        fillColor: Colors.grey,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) => _validatePassword(value!),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign-in button
                  MyButton(onTap: _signIn),

                  const SizedBox(height: 35),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: .5,
                            color: Colors.cyan,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            "Or continue With",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: .5,
                            color: Colors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(imagePath: "lib/images/logos/apple-logo.png"),
                      SizedBox(width: 15),
                      SquareTile(imagePath: "lib/images/logos/google-logo.png"),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Text(
                        "  Not a member?",
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(width: 7.5),
                    ],
                  ),

                  GestureDetector(
                    child: Text(
                      "Register Now",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, "/signup");
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
