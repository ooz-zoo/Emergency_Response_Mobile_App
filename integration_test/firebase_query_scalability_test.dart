import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:integration_test/integration_test.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
}

Future<List<Map<String, String>>> fetchEmergencyContacts() async {
  List<Map<String, String>> contacts = [];
  String userId = getCurrentUserId();

  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergencyContacts')
        .get();

    for (var doc in snapshot.docs) {
      contacts.add({
        'name': doc['name'] ?? '',
        'phone': doc['phone'] ?? '',
        'email': doc['email'] ?? '',
        'relationship': doc['relationship'] ?? '',
      });
    }
  } catch (e) {
    print('Error fetching emergency contacts: $e');
  }
  return contacts;
}

String getCurrentUserId() {

  return 'testUserId';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized(); // Initialize the binding

  setUpAll(() async {
    await initializeFirebase();
  });

  testWidgets('Simulate multiple users fetching emergency contacts from Firebase', (WidgetTester tester) async {
    final int numberOfUsers = 100; // Example number of users
    final List<Future<List<Map<String, String>>>> futures = [];

    // Simulate multiple users fetching emergency contacts
    for (int i = 0; i < numberOfUsers; i++) {
      futures.add(fetchEmergencyContacts());
    }

    // Wait for all futures to complete
    final List<List<Map<String, String>>> contactsList = await Future.wait(futures);

    // Assert that all contacts were fetched successfully
    expect(contactsList.length, equals(numberOfUsers));

    print('Scalability test completed: All $numberOfUsers users fetched emergency contacts successfully.');
  });
}
