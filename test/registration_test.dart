import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journeyai/components/my_button.dart';
import 'package:journeyai/components/square_tile.dart';
import 'package:journeyai/pages/login/registration_page.dart';
import 'package:journeyai/pages/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart'; // Import the mock file

class MockGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async {
    return MockGoogleSignInAccount();
  }
}

class MockGoogleSignInAccount implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async {
    return MockGoogleSignInAuthentication();
  }

  @override
  String get displayName => 'Test User';

  @override
  String get email => 'test@example.com';

  @override
  String get id => 'testId';

  @override
  String get photoUrl => 'https://example.com/photo.jpg';

  @override
  Future<void> clearAuthCache() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<Map<String, String>> get authHeaders async {
    return {'Authorization': 'Bearer testAccessToken'};
  }

  @override
  String get serverAuthCode => 'testServerAuthCode';
}

class MockGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  String get idToken => 'testIdToken';

  @override
  String get accessToken => 'testAccessToken';

  @override
  String get serverAuthCode => 'testServerAuthCode';
}

void main() {
  // Set up Firebase Auth mocks
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('RegistrationPage Tests', () {
    late FirebaseAuthService authService;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late MockGoogleSignIn mockGoogleSignIn;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      mockGoogleSignIn = MockGoogleSignIn();
      authService = FirebaseAuthService();
    });

    testWidgets('Sign-up with email and password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationPage(),
        ),
      );

      // Enter username, email, and password
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'ValidPassword1!');

      // Simulate sign-up
      await tester.tap(find.byType(MyButton));
      await tester.pumpAndSettle();

      // Verify that the user is signed up
      expect(find.text('User successfully created'), findsNothing);
    });

    testWidgets('Google sign-in', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationPage(),
        ),
      );

      await tester.tap(find.byType(SquareTile).first);
      await tester.pumpAndSettle();

      // Verify that the user is signed in
      expect(find.text('Google sign-in failed. Please try again.'), findsNothing);
    });
  });
}
