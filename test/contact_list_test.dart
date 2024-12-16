import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  testWidgets('deleteContact checks if collection is empty', (WidgetTester tester) async {
    final mockUser = MockUser(uid: 'testUserId');
    final mockAuth = MockFirebaseAuth(mockUser: mockUser);
    final mockFirestore = FakeFirebaseFirestore();

    // Add a document to the collection
    await mockFirestore.collection('users')
        .doc(mockUser.uid)
        .collection('emergencyContacts')
        .doc('testDocumentId')
        .set({'name': 'Test Contact'});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await deleteContactStep2(context, 'testDocumentId', mockAuth, mockFirestore);
                },
                child: Text('Delete Contact'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete Contact'));
    await tester.pumpAndSettle();

    // // Verify that the contact was deleted
    // final snapshot = await mockFirestore.collection('users')
    //     .doc(mockUser.uid)
    //     .collection('emergencyContacts')
    //     .get();
    // expect(snapshot.docs.isEmpty, true);
    //
    // // Verify that the navigation occurred
    // expect(find.byType(EmptyApp), findsOneWidget);
  });
}

Future<void> deleteContactStep2(BuildContext context, String documentId, FirebaseAuth auth, FirebaseFirestore firestore) async {
  await firestore.collection('users')
      .doc(auth.currentUser?.uid) // Access the current user's contacts
      .collection('emergencyContacts') // Access sub-collection
      .doc(documentId).delete();

  // After deleting, check if the collection is now empty
  var snapshot = await firestore.collection('users')
      .doc(auth.currentUser?.uid)
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

class EmptyApp extends StatelessWidget {
  const EmptyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('No Contacts'),
      ),
    );
  }
}

// EDIT Test Case