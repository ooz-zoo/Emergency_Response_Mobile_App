import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';

import '../login/login_page.dart';
import 'e_alert.dart';
import 'e_empty.dart';
import 'e_location.dart';
import 'e_logs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Contacts Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ContactScreen(),
    );
  }
}

Color customBlue = Color(0xFF007BFF);
Color customOrange = Color(0xFFFFA500);


class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  int _selectedIndex = 0; // Track the selected tab index

  // Function to delete a contact from Firestore
  void deleteContact(BuildContext context, String documentId) async {
    await FirebaseFirestore.instance.collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid) // Access the current user's contacts
        .collection('emergencyContacts') // Access sub-collection
        .doc(documentId).delete();

    // After deleting, check if the collection is now empty
    var snapshot = await FirebaseFirestore.instance.collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('emergencyContacts').get();

    if (snapshot.docs.isEmpty) {
      // If empty, redirect to the e_empty.dart screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmptyApp()),
      );
    } else {
      // Otherwise, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact deleted successfully!'),
        ),
      );
    }
  }

  // Function to show edit dialog
  void showEditDialog(BuildContext context, Map<String, dynamic> contact, String documentId) {
    final nameController = TextEditingController(text: contact['name']);
    final phoneController = TextEditingController(text: contact['phone']);
    final emailController = TextEditingController(text: contact['email']);
    String relationshipValue = contact['relationship']; // Initial value for the dropdown

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Contact'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                DropdownButtonFormField<String>(
                  value: relationshipValue,
                  items: ['Friend', 'Family', 'Colleague', 'Other'].map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    relationshipValue = newValue!; // Update the selected value
                  },
                  decoration: InputDecoration(labelText: 'Relationship'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Update Firestore with the new values
                await FirebaseFirestore.instance.collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('emergencyContacts')
                    .doc(documentId).update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                  'relationship': relationshipValue,
                });

                // Show confirmation dialog after update
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Update Successful'),
                      content: Text('Contact updated successfully!'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            Navigator.of(context).pop(); // Close the edit dialog
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    // Redirect to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: customBlue,
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView( // Added SingleChildScrollView
                  child: Column(
                    children: [
                      SizedBox(height: 25), // Adjust this height to push the image down
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
                        children: [
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('lib/pages/ern/assets/contact_book.png'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          const SizedBox(width: 25), // Horizontal space between image and text
                          const Text(
                            'EMERGENCY CONTACTS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
      Expanded(
        flex: 6,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Matches the inner Container color
            border: Border.all(
              color: Colors.black,
              width: 3.0,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
            child: Container(
              color: Colors.white, // Matches the parent Container color
              padding: const EdgeInsets.all(26.0),
              child: Column(
                children: [
                  Expanded(
                    // Your existing StreamBuilder code goes here
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('emergencyContacts')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => EmptyApp()),
                            );
                          });
                          return Container();
                        }

                        final contacts = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index].data() as Map<String, dynamic>;
                            final documentId = contacts[index].id;
                            final name = contact['name'] ?? 'N/A';
                            final phone = contact['phone'] ?? 'N/A';
                            final email = contact['email'] ?? 'N/A';
                            final relationship = contact['relationship'] ?? 'N/A';

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                elevation: 4,
                                child: ExpansionTile(
                                  title: Text(
                                    'Emergency Contact ${index + 1}: $name',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Phone: $phone'),
                                          Text('Email: $email'),
                                          Text('Relationship: $relationship'),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () {
                                                  showEditDialog(context, contact, documentId);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () {
                                                  deleteContact(context, documentId);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customOrange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/contact_form');
                      },
                      child: const Text('Add Emergency Contact'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      ],
      )

    );
  }
}
