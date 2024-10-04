import "package:flutter/material.dart";
import "package:journeyai/components/my_button.dart";
import "package:journeyai/components/my_textfield.dart";
import "package:journeyai/components/square_tile.dart";

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  //text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  void signUserIn() {}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB2BEC3),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              //logo
              SquareTile(imagePath: "lib/images/logos/logo3.png"),
              const SizedBox(height: 60),
              //welcome back ,
              const Text(
                "Welcome back",
                style: TextStyle(
                  color: Color(0xFFD63031),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),
              // username
              MyTextField(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),
              const SizedBox(height: 15),
              //password
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 15),
              //forgot password
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Forgot Password",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              //signin button
              MyButton(onTap: signUserIn),

              const SizedBox(height: 30),
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: .5,
                        color: Colors.cyan,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  // google Button
                  SquareTile(imagePath: "lib/images/logos/apple-logo.png"),

                  SizedBox(
                    width: 15,
                  ),
                  //apple Button
                  SquareTile(imagePath: "lib/images/logos/google-logo.png")
                ],
              ),
              const SizedBox(height: 30),
              const Row(
                children: [
                  Text(
                    "Not a member?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(
                    width: 7.5,
                  ),
                  Text(
                    "Register Now",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  )
                ],
              )

              //not a member register
            ],
          ),
        ),
      ),
    );
  }
}
