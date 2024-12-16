// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
//
// void main() {
//   group('Emergency Contacts Tests', () {
//     testWidgets('Check emergency contacts', (WidgetTester tester) async {
//       final mockUser = MockUser(uid: 'testUserId');
//       final mockAuth = MockFirebaseAuth(mockUser: mockUser);
//       final mockFirestore = FakeFirebaseFirestore();
//
//       // Add a document to the collection
//       await mockFirestore.collection('users')
//           .doc(mockUser.uid)
//           .collection('emergencyContacts')
//           .doc('testDocumentId')
//           .set({'name': 'Test Contact'});
//
//       await tester.pumpWidget(
//         MaterialApp(
//           routes: {
//             '/e_dashboard': (context) => EmergencyDashboard(),
//             '/empty': (context) => EmptyScreen(),
//           },
//           home: Scaffold(
//             body: Builder(
//               builder: (context) {
//                 return ElevatedButton(
//                   onPressed: () async {
//                     await _checkEmergencyContacts(mockUser, mockFirestore, context);
//                   },
//                   child: Text('Check Emergency Contacts'),
//                 );
//               },
//             ),
//           ),
//         ),
//       );
//
//       await tester.tap(find.text('Check Emergency Contacts'));
//       await tester.pumpAndSettle();
//
//       // Verify that the navigation occurred
//       expect(find.byType(EmergencyDashboard), findsOneWidget);
//     });
//
//     testWidgets('Check empty emergency contacts', (WidgetTester tester) async {
//       final mockUser = MockUser(uid: 'testUserId');
//       final mockAuth = MockFirebaseAuth(mockUser: mockUser);
//       final mockFirestore = FakeFirebaseFirestore();
//
//       await tester.pumpWidget(
//         MaterialApp(
//           routes: {
//             '/e_dashboard': (context) => EmergencyDashboard(),
//             '/empty': (context) => EmptyScreen(),
//           },
//           home: Scaffold(
//             body: Builder(
//               builder: (context) {
//                 return ElevatedButton(
//                   onPressed: () async {
//                     await _checkEmergencyContacts(mockUser, mockFirestore, context);
//                   },
//                   child: Text('Check Emergency Contacts'),
//                 );
//               },
//             ),
//           ),
//         ),
//       );
//
//       await tester.tap(find.text('Check Emergency Contacts'));
//       await tester.pumpAndSettle();
//
//       // Verify that the navigation occurred
//       expect(find.byType(EmptyScreen), findsOneWidget);
//     });
//   });
//
//   group('Validation Tests', () {
//     test('Email validation', () {
//       expect(_validateEmail(''), 'Email cannot be empty');
//       expect(_validateEmail('invalid-email'), 'Please enter a valid email');
//       expect(_validateEmail('test@example.com'), null);
//     });
//
//     test('Password validation', () {
//       expect(_validatePassword(''), 'Password cannot be empty');
//       expect(_validatePassword('short'), 'Password must be at least 8 characters');
//       expect(_validatePassword('validpassword'), null);
//     });
//   });
// }
//
// Future<void> _checkEmergencyContacts(User user, FirebaseFirestore firestore, BuildContext context) async {
//   // Reference the Firestore collection for the current user's emergency contacts
//   CollectionReference emergencyContacts = firestore
//       .collection('users')
//       .doc(user.uid) // Current user's document
//       .collection('emergencyContacts');
//
//   // Get the documents from the sub-collection
//   QuerySnapshot snapshot = await emergencyContacts.get();
//
//   if (snapshot.docs.isNotEmpty) {
//     print('Emergency contacts found');
//     Navigator.pushNamed(context, "/e_dashboard"); //changing point here
//   } else {
//     print('No emergency contacts found');
//     Navigator.pushNamed(context, "/empty");
//   }
// }
//
// class EmergencyDashboard extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text('Emergency Dashboard'),
//       ),
//     );
//   }
// }
//
// class EmptyScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text('No Emergency Contacts'),
//       ),
//     );
//   }
// }
//
// String? _validateEmail(String value) {
//   if (value.isEmpty) {
//     return 'Email cannot be empty';
//   } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//     return 'Please enter a valid email';
//   }
//   return null;
// }
//
// String? _validatePassword(String value) {
//   if (value.isEmpty) {
//     return 'Password cannot be empty';
//   } else if (value.length < 8) {
//     return 'Password must be at least 8 characters';
//   }
//   return null;
// }

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journeyai/components/my_button.dart';
import 'package:journeyai/components/square_tile.dart';
import 'package:journeyai/pages/login/login_page.dart';
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

  group('LoginPage Tests', () {
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

    testWidgets('Google sign-in', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.tap(find.byType(SquareTile).first);
      await tester.pumpAndSettle();

      // Verify that the user is signed in
      expect(find.text('Google sign-in failed. Please try again.'), findsNothing);
    });

    testWidgets('Email/password sign-in', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // Enter email and password
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'validpassword');

      // Simulate email/password sign-in
      await tester.tap(find.byType(MyButton));
      await tester.pumpAndSettle();

      // Verify that the user is signed in
      expect(find.text('Login failed. Please try again.'), findsNothing);
    });
  });
}




