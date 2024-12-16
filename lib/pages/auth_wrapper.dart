import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journeyai/pages/login_page.dart';
import 'package:journeyai/pages/wallet.dart'; // Use MainHome if available
import 'package:journeyai/pages/main_home.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Loading state
          } else if (snapshot.hasData) {
            return DashboardScreen(detectedCondition: 'Sober/Awake', detectedTime: DateTime.now()); // Go to MainHome if user is logged in // change later on
          } else {
            return LornaLoginPage(); // Go to login page if not logged in
          }
        },
      ),
    );
  }
}