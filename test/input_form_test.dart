import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('Firestore and FirebaseAuth Mock Tests', () {
    final mockAuth = MockFirebaseAuth();
    final mockFirestore = FakeFirebaseFirestore();

    // This will store our test results
    final testResults = <String, bool>{};

    // Simulating controllers for name, phone, and email
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    // Error variables
    String? nameError;
    String? phoneError;
    String? emailError;

    // Validation function
    void validateInputs() {
      // Validate name
      if (nameController.text.isEmpty) {
        nameError = 'Please enter your name';
      }

      // Validate phone number
      String phoneNumber = phoneController.text;
      if (phoneNumber.isEmpty) {
        phoneError = 'Please enter your phone number';
      } else if (phoneNumber.length != 13 || !phoneNumber.startsWith('+254')) {
        phoneError = 'Phone number must be in the format +254712345678';
      } else {
        phoneError = null; // Ensure phoneError is null if the phone number is valid
      }

      // Validate email
      String email = emailController.text;
      if (email.isEmpty) {
        emailError = 'Please enter your email address';
      } else if (!email.contains('@') || !email.contains('.')) {
        emailError = 'Please enter a valid email address E.g., example@mail.com';
      } else {
        emailError = null; // Ensure emailError is null if the email is valid
      }
    }

    test('Add emergency contact to Firestore', () async {
      // Mock a signed-in user
      final mockUser = await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      );

      // Ensure the user is signed in
      testResults['Add emergency contact to Firestore'] = mockAuth.currentUser != null;

      // Mock Firestore write
      await mockFirestore
          .collection('users')
          .doc(mockAuth.currentUser!.uid)
          .collection('emergencyContacts')
          .add({
        'name': 'John Doe',
        'phone': '+254704589302',
        'email': 'john.doe@example.com',
        'relationship': 'Family',
      });

      // Verify Firestore write
      final snapshot = await mockFirestore
          .collection('users')
          .doc(mockAuth.currentUser!.uid)
          .collection('emergencyContacts')
          .get();

      final passed = snapshot.docs.length == 1 && snapshot.docs.first['name'] == 'John Doe';
      testResults['Add emergency contact to Firestore'] = passed;

      // --- Validation Section ---
      // Test Name Validation
      nameController.text = '';
      validateInputs();
      expect(nameError, 'Please enter your name'); // Name error validation

      // Test Phone Validation
      phoneController.text = '+254712345678'; // Valid phone number
      validateInputs();
      expect(phoneError, null); // No error expected

      phoneController.text = '712345678'; // Invalid phone number
      validateInputs();
      expect(phoneError, 'Phone number must be in the format +254712345678'); // Phone error validation

      // Test Email Validation
      emailController.text = 'testemail.com'; // Invalid email
      validateInputs();
      expect(emailError, 'Please enter a valid email address E.g., example@mail.com'); // Email error validation

      emailController.text = 'test@example.com'; // Valid email
      validateInputs();
      expect(emailError, null); // No error expected
    });

    // Custom Test Results Summary
    tearDownAll(() {
      // Print out the results summary at the end
      print('\nTest Results Summary:');
      testResults.forEach((testName, result) {
        print('$testName: ${result ? 'PASSED' : 'FAILED'}');
      });
    });
  });
}