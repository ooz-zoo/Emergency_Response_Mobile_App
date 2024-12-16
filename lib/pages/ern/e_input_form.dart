import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'e_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp( debugShowCheckedModeBanner: false,
      title: 'Emergency input Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FormScreen(),
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({Key? key}) : super(key: key);

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? selectedRelationship;

  void validateForm() {
    String nameError = '';
    String phoneError = '';
    String emailError = '';
    String relationshipError = '';

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
    }

    // Validate email
    String email = emailController.text;
    if (email.isEmpty) {
      emailError = 'Please enter your email address';
    } else if (!email.contains('@') || !email.contains('.')) {
      emailError = 'Please enter a valid email address E.g., example@mail.com';
    }

    // Validate relationship
    if (selectedRelationship == null) {
      relationshipError = 'Please select a relationship';
    }

    // Show validation errors
    if (nameError.isNotEmpty || phoneError.isNotEmpty || emailError.isNotEmpty || relationshipError.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Validation Errors'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (nameError.isNotEmpty) Text(nameError),
                if (phoneError.isNotEmpty) Text(phoneError),
                if (emailError.isNotEmpty) Text(emailError),
                if (relationshipError.isNotEmpty) Text(relationshipError),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // If no validation errors, proceed to send the data to Firestore
      saveToFirestore();
    }
  }

  void saveToFirestore() async {
    // Get the current user's ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in first.')),
      );
      return;
    }

    String name = nameController.text;
    String phone = phoneController.text;
    String email = emailController.text;

    // Send the form data to Firestore under the user's emergencyContacts sub-collection
    try {
      await FirebaseFirestore.instance
          .collection('users') // Ensure you're in the correct users collection
          .doc(user.uid) // Use the current user's ID
          .collection('emergencyContacts') // Navigate to the sub-collection
          .add({
        'name': name,
        'phone': phone,
        'email': email,
        'relationship': selectedRelationship, // Save the selected relationship
      });

      // Show a success message in a dialog that disappears after 2 seconds
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Emergency contact added successfully!'),
            actions: [],
          );
        },
      );

      // Close the dialog after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Close the dialog
      });

      // Wait for 2 seconds and then navigate to the dashboard
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushNamed(context, "/e_dashboard");
      });

      // Clear input fields
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      setState(() {
        selectedRelationship = null; // Clear the relationship selection
      });
    } catch (error) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add contact: $error')),
      );
    }
  }

  Color customBlue = Color(0xFF007BFF);
  Color customOrange = Color(0xFFFFA500);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBlue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('lib/pages/ern/assets/add_contact.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'EMERGENCY CONTACT FORM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 3.0,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0),
                  ),
                ),
                padding: const EdgeInsets.all(26.0),
                child: SingleChildScrollView( // Make the form scrollable
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Emergency Contact Name field
                      const Text(
                        'Emergency Contact Name',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'First and Last Name',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),

                      // Relationship Dropdown
                      const Text(
                        'Relationship',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedRelationship,
                        items: <String>[
                          'Family',
                          'Friend',
                          'Colleague',
                          'Other',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRelationship = newValue;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Select Relationship',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone Number field
                      const Text(
                        'Phone Number',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'e.g., +254712345678',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),

                      // Email field
                      const Text(
                        'Email',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'e.g., example@mail.com',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 30),

                      // Register Button
                      Center(
                        child: ElevatedButton(
                          onPressed: validateForm,
                          child: const Text('Register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customOrange, // Background color
                            foregroundColor: Colors.white, // Text color
                            minimumSize: const Size(350, 50), // Width and height of the button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Rounded corners
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}