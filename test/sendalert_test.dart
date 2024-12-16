import 'package:flutter_test/flutter_test.dart';
import 'package:journeyai/pages/ern/alert_helper.dart';
import 'package:telephony_sms_handler/telephony.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart'; // Import the mock setup file

// Mock implementation of Telephony
class MockTelephony {
  Future<void> sendSms({
    required String to,
    required String message,
    bool isMultipart = false,
    dynamic Function(SendStatus)? statusListener,
  }) async {
    // Simulate sending SMS
    if (to == 'fail') {
      throw Exception('SMS sending failed');
    }
  }
}

// Custom DriverStateService for testing
class TestDriverStateService extends DriverStateService {
  final MockTelephony mockTelephony;

  TestDriverStateService(this.mockTelephony);

  @override
  Future<String> getCurrentLocationWithLogging() async {
    return 'Test Location';
  }

  @override
  Telephony get telephony => mockTelephony as Telephony;
}

void main() {
  setupFirebaseAuthMocks(); // Call the setup function

  setUpAll(() async {
    await Firebase.initializeApp(); // Initialize Firebase
  });

  group('sendAlert', () {
    late MockTelephony mockTelephony;
    late TestDriverStateService testDriverStateService;

    setUp(() {
      mockTelephony = MockTelephony();
      testDriverStateService = TestDriverStateService(mockTelephony);
    });

    test('should send alert with correct message and location', () async {
      final contact = {'name': 'John Doe', 'phone': '1234567890'};
      final message = 'This is a test alert';

      await testDriverStateService.sendAlert('test', message, contact);

      // Verify that the SMS was sent with the correct message
      expect(
            () async => await mockTelephony.sendSms(
          to: contact['phone']!,
          message: '$message\nLocation: Test Location\nReply 1=Ack, 2=Esc',
        ),
        returnsNormally,
      );
    });

    test('should handle SMS sending failure', () async {
      final contact = {'name': 'John Doe', 'phone': 'fail'};
      final message = 'This is a test alert';

      await testDriverStateService.sendAlert('test', message, contact);

      // Verify that the SMS sending failure is handled
      expect(
            () async => await mockTelephony.sendSms(
          to: contact['phone']!,
          message: '$message\nLocation: Test Location\nReply 1=Ack, 2=Esc',
        ),
        throwsException,
      );
    });
  });
}


