import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:journeyai/pages/sign_up_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:journeyai/services/auth_services.dart';
import 'package:journeyai/components/password_textfield.dart';
import 'package:journeyai/components/my_textfield.dart';
import 'mock.dart'; // Import the mock setup file
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core

void main() {
  setupFirebaseAuthMocks(); // Call the setup function

  setUpAll(() async {
    await Firebase.initializeApp(); // Initialize Firebase
  });

  testWidgets('RegistrationPage registration test', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final fakeFirestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: mockAuth),
          Provider<FirebaseFirestore>.value(value: fakeFirestore),
          Provider<AuthService>(
            create: (_) => AuthService(),
          ),
        ],
        child: MaterialApp(
          home: LornaRegistrationPage(),
        ),
      ),
    );

    // Enter user details with invalid password
    await tester.enterText(find.byType(MyTextField).at(0), 'testuser');
    await tester.enterText(find.byType(MyTextField).at(1), 'Test User');
    await tester.enterText(find.byType(MyTextField).at(2), 'test@example.com');
    await tester.enterText(find.byType(MyTextField).at(3), '1234567890');
    await tester.enterText(find.byType(MyTextField).at(4), '123 Test St');
    await tester.enterText(find.byType(MyPasswordTextField).at(0), 'password123');
    await tester.enterText(find.byType(MyPasswordTextField).at(1), 'password123');

    // Scroll the "Sign up" button into view and tap it
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Verify form validation fails
    expect(find.text('Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character.'), findsNWidgets(2));

    // Enter user details with valid password
    await tester.enterText(find.byType(MyPasswordTextField).at(0), 'Password@123');
    await tester.enterText(find.byType(MyPasswordTextField).at(1), 'Password@123');

    // Scroll the "Sign up" button into view and tap it
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Print a message indicating the test passed
    print('Registration test passed!');
  });
}

