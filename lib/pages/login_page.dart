//import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:journeyai/components/password_textfield.dart";
import "package:journeyai/pages/forgot_password.dart";
import "package:journeyai/services/auth_services.dart";
import "../components/my_textfield.dart";
import 'package:journeyai/pages/auth_wrapper.dart';
import '../pages/sign_up_page.dart';
import 'package:local_auth/local_auth.dart';

class LornaLoginPage extends StatefulWidget {
  const LornaLoginPage({super.key});

  @override
  State<LornaLoginPage> createState() => _LornaLoginPageState();
}

class _LornaLoginPageState extends State<LornaLoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool isSigningIn = false;

  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false; //varible to check if user is authenticated
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void loginUser() async {
    try {
      setState(() {
        isSigningIn = true;
      });
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        ); // Return to AuthWrapper after logging in
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(_authService.errorMessages(e.toString()));
      }
    }
    setState(() {
      isSigningIn = false;
    });
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      if (canAuthenticateWithBiometrics) {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Please authenticate to log in',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (mounted) {
          setState(() {
            _isAuthenticated = didAuthenticate;
          });
        }
      } else {
        setState(() {
          _isAuthenticated = false; //toggle the authentication state
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Biometrics failed! Please try again"),
            duration: Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.blue[50],
      resizeToAvoidBottomInset: false, //check what this is
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //const SizedBox(height: 60),
                //logo
                Image.asset(
                  "images/journey_ai_writing_logo_nobg_cropped.png",
                  width: screenWidth - 100,
                  height: screenWidth - 100,
                ),
                //SquareTile(imagePath: "images/journey_ai_writing_logo.jpeg"),
                //const SizedBox(height: 60),
                //welcome back ,
                Text(
                  "Welcome back",
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 30),
                // username
                MyTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  obscureText: false,
                  filled: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                //password
                MyPasswordTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  filled: true,
                ),
                const SizedBox(height: 15),
                //forgot password
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ForgotPassword()),
                          );
                        },
                        child: Text(
                          "Forgot Password",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                //signin button
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await _authenticate();
                      if (_isAuthenticated) {
                        loginUser();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Please correct the errors in the form')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue[900],
                      minimumSize: Size(screenWidth - 30, 50)),
                  child: isSigningIn
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("Login"),
                ),

                const SizedBox(height: 30),
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
                            color: Colors.black,
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
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // apple Button
                      GestureDetector(
                        onTap: () {},
                        child: Icon(
                          Icons.apple, // Apple icon
                          // Set the color of the icon
                          size: 60, // Set the size of the icon
                        ),
                      ),
                      //google Button
                      GestureDetector(
                        onTap: () {
                          _authService.signInWithGoogle();
                        },
                        child: Icon(
                          Icons.g_mobiledata, // google icon
                          // Set the color of the icon
                          size: 70, // Set the size of the icon
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(30.0, 0, 0, 0),
                        child: Text(
                          "Not a member?",
                          style: TextStyle(color: Colors.black),
                        )),
                    SizedBox(
                      width: 7.5,
                    ),
                    Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                        child: Column(children: [
                          GestureDetector(
                            onTap: () {
                              // Navigate to the registration page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LornaRegistrationPage()),
                              );
                            },
                            child: Text(
                              "Sign up",
                              style: TextStyle(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600),
                            ),
                          )
                        ]))
                  ],
                )

                //not a member register
              ],
            ),
          ),
        ),
      ),
    );
  }
}
