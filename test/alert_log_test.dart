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

  Future<String> logAlertToFirestore(String alertType, String message,
      String response, String contactID, String contactName, String location,
      String driverStatus) async {
    String userId = _auth.currentUser?.uid ?? '';
    DateTime timestamp = DateTime.now();

    try {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('alertLogs')
          .add({
        'ResponseType': alertType,
        'message': message,
        'response': response,
        'contactID': contactID,
        'contactName': contactName,
        'location': location,
        'driverStatus': driverStatus,
        'timestamp': timestamp,
      });

      print('Alert logged with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error logging alert: $e');
      return '';
    }
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

  test('logAlertToFirestore logs alert and returns document ID', () async {
    // Arrange
    final alertType = 'Test Alert';
    final message = 'This is a test message';
    final response = 'Test Response';
    final contactID = 'contact123';
    final contactName = 'John Doe';
    final location = 'Test Location';
    final driverStatus = 'Test Status';

    // Mock a signed-in user
    await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'Password@123',
    );

    // Act
    final docId = await mockService.logAlertToFirestore(
        alertType, message, response, contactID, contactName, location, driverStatus);

    // Assert
    expect(docId, isNotEmpty);

    final docSnapshot = await fakeFirestore
        .collection('users')
        .doc(mockAuth.currentUser!.uid)
        .collection('alertLogs')
        .doc(docId)
        .get();

    expect(docSnapshot.exists, isTrue);
    expect(docSnapshot['ResponseType'], alertType);
    expect(docSnapshot['message'], message);
    expect(docSnapshot['response'], response);
    expect(docSnapshot['contactID'], contactID);
    expect(docSnapshot['contactName'], contactName);
    expect(docSnapshot['location'], location);
    expect(docSnapshot['driverStatus'], driverStatus);
  });
}
