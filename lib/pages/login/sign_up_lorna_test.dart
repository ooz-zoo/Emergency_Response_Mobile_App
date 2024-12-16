// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// import 'package:journeyai/pages/sign_up_page.dart';
// import 'package:journeyai/pages/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:journeyai/components/password_textfield.dart';
// import 'package:journeyai/components/my_textfield.dart';
// import 'package:journeyai/pages/sign_up_page.dart';
// import 'package:journeyai/services/auth_services.dart';
// import 'mock.dart'; // Import the mock file
//
// void main() {
//   // Set up Firebase Auth mocks
//   setupFirebaseAuthMocks();
//
//   setUpAll(() async {
//     await Firebase.initializeApp();
//   });
//
//   group('LornaRegistrationPage Tests', () {
//     late AuthService authService;
//     late MockFirebaseAuth mockAuth;
//     late FakeFirebaseFirestore mockFirestore;
//
//     setUp(() {
//       mockAuth = MockFirebaseAuth();
//       mockFirestore = FakeFirebaseFirestore();
//       authService = AuthService();
//     });
//
//     testWidgets('Sign-up with email and password', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: LornaRegistrationPage(),
//         ),
//       );
//
//       // Enter user details
//       await tester.enterText(find.byType(MyTextField).at(0), 'testuser');
//       await tester.enterText(find.byType(MyTextField).at(1), 'Test User');
//       await tester.enterText(find.byType(MyTextField).at(2), 'test@example.com');
//       await tester.enterText(find.byType(MyTextField).at(3), '1234567890');
//       await tester.enterText(find.byType(MyTextField).at(4), '123 Test St');
//       await tester.enterText(find.byType(MyPasswordTextField).at(0), 'ValidPassword1!');
//       await tester.enterText(find.byType(MyPasswordTextField).at(1), 'ValidPassword1!');
//
//       // Simulate sign-up
//       await tester.tap(find.byType(ElevatedButton).first);
//       await tester.pumpAndSettle();
//
//       // Verify that the registration was successful
//       expect(find.text('Registration successful'), findsOneWidget);
//     });
//
//     testWidgets('Choose image from gallery', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: LornaRegistrationPage(),
//         ),
//       );
//
//       // Simulate choosing an image from the gallery
//       await tester.tap(find.byIcon(Icons.photo_library));
//       await tester.pumpAndSettle();
//
//       // Verify that an image was selected
//       expect(find.byType(Image), findsOneWidget);
//     });
//
//     testWidgets('Capture image from camera', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: LornaRegistrationPage(),
//         ),
//       );
//
//       // Simulate capturing an image from the camera
//       await tester.tap(find.byIcon(Icons.camera_alt));
//       await tester.pumpAndSettle();
//
//       // Verify that an image was captured
//       expect(find.byType(Image), findsOneWidget);
//     });
//   });
// }
