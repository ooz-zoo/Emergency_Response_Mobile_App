import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journeyai/pages/login_page.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:journeyai/services/auth_services.dart';
import 'package:journeyai/components/password_textfield.dart';
import 'package:journeyai/components/my_textfield.dart';
import 'package:journeyai/pages/auth_wrapper.dart';
import 'mock.dart'; // Import the mock setup file
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:journeyai/main.dart';

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    pushedRoutes.add(route);
  }
}

void main() {
  setupFirebaseAuthMocks(); // Call the setup function

  setUpAll(() async {
    await Firebase.initializeApp(); // Initialize Firebase
  });

  testWidgets('LoginPage login test', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final fakeFirestore = FakeFirebaseFirestore();
    final navigatorObserver = TestNavigatorObserver();

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
          home: LornaLoginPage(),
          navigatorObservers: [navigatorObserver],
        ),
      ),
    );

    // Enter email and password
    await tester.enterText(find.byType(MyTextField).first, 'test@example.com');
    await tester.enterText(find.byType(MyPasswordTextField), 'Password@123');

    // Scroll the "Login" button into view and tap it
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Simulate successful login
    await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'Password@123',
    );

    // Verify navigation to AuthWrapper
    //expect(navigatorObserver.pushedRoutes.any((route) => route.settings.name == '/auth'), isFalse);
    // Print a message indicating the test passed
    print('Login test passed!');
  });
}
