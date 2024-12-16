import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journeyai/pages/ern/e_empty.dart';
import 'package:journeyai/pages/ern/e_input_form.dart';

void main() {
  final List<String> results = []; // List to store test results.

  // Custom test wrapper to collect results
  void customTest(String description, Future<void> Function(WidgetTester) testBody) {
    testWidgets(description, (WidgetTester tester) async {
      try {
        await testBody(tester);
        results.add('$description: PASSED');
      } catch (e, stackTrace) {
        results.add('$description: FAILED\nReason: $e\n$stackTrace');
        rethrow; // Ensure test failure is caught by the framework.
      }
    });
  }

  group('EmptyApp Tests', () {
    customTest('EmptyApp displays an image', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EmptyApp()));
      expect(find.byType(Image), findsOneWidget);
    });

    customTest('EmptyApp displays the correct text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EmptyApp()));
      expect(find.text('No Emergency Contacts Found'), findsOneWidget);
      expect(find.text('Register Emergency Contact'), findsOneWidget);
    });

    customTest('EmptyApp navigates to FormScreen on button press', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EmptyApp(),
        routes: {
          '/form': (context) => FormScreen(),
        },
      ));
      await tester.tap(find.text('Register Emergency Contact'));
      await tester.pumpAndSettle();
      expect(find.byType(FormScreen), findsOneWidget);
    });
  });

  tearDownAll(() {
    // Print all test results after the test suite completes.
    print('\nTest Results Summary:');
    for (final result in results) {
      print(result);
    }
  });
}
