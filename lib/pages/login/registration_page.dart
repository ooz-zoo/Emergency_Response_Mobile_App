import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:journeyai/components/my_button.dart';
import 'package:journeyai/components/square_tile.dart';
import 'package:journeyai/pages/user_auth/firebase_auth_implementation/firebase_auth_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase initialization
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RegistrationPage(),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuthService _auth = FirebaseAuthService(); // allows access to Firebase auth methods
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // GlobalKey for form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Password validation logic
  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password cannot be empty';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    } else if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    } else if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    } else if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Email validation logic
  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Sign-up method with validation
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      String username = _usernameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;

      User? user = await _auth.signUpWithEmailAndPassword(email, password);

      if (user != null) {
        // Store user data in Firestore without emergency contacts array
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
        });

        print("User successfully created");
        Navigator.pushNamed(context, "/login");
      } else {
        print("User not created");
      }
    }
  }

  // Password visibility
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2BEC3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formKey, // Wrap the form with GlobalKey for full validation
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Logo
                  SquareTile(imagePath: "lib/images/logos/logo3.png"),
                  const SizedBox(height: 5),
                  // Registration title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Color(0xFFD63031),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Username',
                        fillColor: Colors.grey,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

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
                            _isPasswordVisible ? Icons.visibility : Icons
                                .visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      // Toggle password visibility
                      validator: (value) => _validatePassword(value!),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register button
                  MyButton(onTap: () => _signup()),
                  const SizedBox(height: 35),

                  // Additional fields
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
                  const SizedBox(height: 20),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Button
                      SquareTile(imagePath: "lib/images/logos/google-logo.png"),
                      SizedBox(width: 15),
                      // Apple Button
                      SquareTile(imagePath: "lib/images/logos/apple-logo.png"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Text(
                        "  Already have an account?",
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(width: 7.5),
                    ],
                  ),
                  GestureDetector(
                    child: Text("Login Now",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, "/login");
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
