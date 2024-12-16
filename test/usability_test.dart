// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:journeyai/pages/login_page.dart';
//
// void main() {
//   testWidgets('Login page is accessible', (WidgetTester tester) async {
//     await tester.pumpWidget(MaterialApp(
//       home: LornaLoginPage(),
//     ));
//
//     // Check for accessibility labels
//     expect(find.bySemanticsLabel('Email'), findsOneWidget);
//     expect(find.bySemanticsLabel('Password'), findsOneWidget);
//     expect(find.bySemanticsLabel('Login'), findsOneWidget);
//
//     // Check for high contrast mode
//     final Finder emailField = find.byKey(Key('emailField'));
//     final Finder passwordField = find.byKey(Key('passwordField'));
//     final Finder loginButton = find.byType(ElevatedButton);
//
//     expect(emailField, findsOneWidget);
//     expect(passwordField, findsOneWidget);
//     expect(loginButton, findsOneWidget);
//
//     // Ensure the text fields and button are visible and accessible
//     expect(tester.getSemantics(emailField), isNotNull);
//     expect(tester.getSemantics(passwordField), isNotNull);
//     expect(tester.getSemantics(loginButton), isNotNull);
//   });
// }
