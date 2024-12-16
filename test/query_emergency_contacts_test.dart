import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock Service Class
class MockService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MockService(this._firestore, this._auth);

  Future<List<Map<String, String>>> fetchEmergencyContacts() async {
    List<Map<String, String>> contacts = [];
    String userId = _auth.currentUser?.uid ?? '';

    try {
      QuerySnapshot snapshot = await _firestore
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
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockService mockService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockService = MockService(fakeFirestore, mockAuth);
  });

  test('fetchEmergencyContacts returns list of contacts', () async {
    // Arrange
    await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );

    // Add mock data to Firestore
    await fakeFirestore
        .collection('users')
        .doc(mockAuth.currentUser!.uid)
        .collection('emergencyContacts')
        .add({
      'name': 'John Doe',
      'phone': '+254712345678',
      'email': 'john.doe@example.com',
      'relationship': 'Friend',
    });

    await fakeFirestore
        .collection('users')
        .doc(mockAuth.currentUser!.uid)
        .collection('emergencyContacts')
        .add({
      'name': 'Jane Smith',
      'phone': '+254712345679',
      'email': 'jane.smith@example.com',
      'relationship': 'Family',
    });

    // Act
    final contacts = await mockService.fetchEmergencyContacts();

    // Assert
    expect(contacts.length, 2);
    expect(contacts[0]['name'], 'John Doe');
    expect(contacts[0]['phone'], '+254712345678');
    expect(contacts[0]['email'], 'john.doe@example.com');
    expect(contacts[0]['relationship'], 'Friend');
    expect(contacts[1]['name'], 'Jane Smith');
    expect(contacts[1]['phone'], '+254712345679');
    expect(contacts[1]['email'], 'jane.smith@example.com');
    expect(contacts[1]['relationship'], 'Family');
  });
}
