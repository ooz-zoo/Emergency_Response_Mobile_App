import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../components/my_textfield.dart";

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(" Password reset email sent! Check your email."),
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message.toString()),
        ));
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
                  "Password reset",
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  "Enter your email address below and we will send you a password reset link",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
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

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Processing Data')),
                      );
                    }
                    passwordReset();
                  },
                  child: Text('Send password reset link'),
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
