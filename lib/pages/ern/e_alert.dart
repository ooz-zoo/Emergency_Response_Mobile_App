import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telephony_sms_handler/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'dart:async';
import 'simulation_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver Alert System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AlertScreen(),
    );
  }
}

class AlertGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Telephony telephony = Telephony.instance;

  // Fetch the user's unique ID
  String getCurrentUserId() {
    User? user = _auth.currentUser;
    return user != null ? user.uid : '';
  }

  // Retrieve emergency contacts from Firestore
  Future<List<Map<String, String>>> fetchEmergencyContacts() async {
    List<Map<String, String>> contacts = [];
    String userId = getCurrentUserId();

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

  // Function to log alert to Firestore
  Future<String> logAlertToFirestore(String alertType,
      String message,
      String response,
      String contactID,
      String contactName,
      String location,
      String driverStatus) async {
    String userId = getCurrentUserId();
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
        'contactName': contactName, // Add the contact's name
        'location': location, // Add the location
        'driverStatus': driverStatus, // Add the driver status
        'timestamp': timestamp,
      });

      print('Alert logged with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error logging alert: $e');
      return '';
    }
  }


  Future<void> sendAlert(String alertType, String message,
      Map<String, String> contact) async {
    // Fetch location with logging
    String location = await getCurrentLocationWithLogging();

    // Combine message and location
    String fullMessage = '$message\nLocation: $location\nReply 1=Ack, 2=Esc';
    print('Full message: $fullMessage');
    print('Full message length: ${fullMessage.length} characters');

    print('Sending alert to ${contact['name']} at ${contact['phone']}');
    try {
      await telephony.sendSms(
        to: contact['phone'] ?? '',
        message: fullMessage,
      );
      print('SMS sent successfully to ${contact['phone']}');
    } catch (e) {
      print('Failed to send SMS: $e');
    }
  }

  Future<String> getCurrentLocationWithLogging() async {
    print('Starting to fetch location...');
    DateTime startTime = DateTime.now();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied.');
        return 'Location permission denied.';
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocoding to get address details
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );

      String street = placemarks[0].street ?? 'Unknown street';
      String city = placemarks[0].locality ?? 'Unknown city';

      // Generate Google Maps URL
      //String mapUrl = 'https://goo.gl/maps/?q=${position.latitude},${position
      //.longitude}';
      String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      String location = '$street, $city\nMap: $mapUrl';
      DateTime endTime = DateTime.now();
      print('Location fetched: $location');
      print('Time taken to fetch location: ${endTime
          .difference(startTime)
          .inSeconds} seconds');
      return location;
    } catch (e) {
      print('Failed to get location: $e');
      return 'Failed to get location.';
    }
  }

  // Escalation process if acknowledgment fails (retry logic here)
  Future<void> checkAcknowledgmentWithRetries(BuildContext context, List<Map<String, String>> emergencyContacts, int retryCount, DateTime alertSentTime, String location, String driverStatus) async {
    if (retryCount >= emergencyContacts.length) {
      print('No more contacts to escalate to.');
      return;
    }

    try {
      List<SmsMessage> messages = await telephony.getInboxSms(
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(emergencyContacts[retryCount]['phone'] ?? ''),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      if (messages.isNotEmpty) {
        SmsMessage latestMessage = messages.first;

        if (latestMessage.date != null) {
          DateTime latestMessageDate = DateTime.fromMillisecondsSinceEpoch(latestMessage.date!);

          if (latestMessageDate.isAfter(alertSentTime)) {
            String contactPhone = emergencyContacts[retryCount]['phone'] ?? 'Unknown contact';
            String contactName = emergencyContacts[retryCount]['name'] ?? 'Unknown contact';

            if (latestMessage.body == '1') {
              print('Acknowledgment received!');
              showAcknowledgmentSnackbar(context); // Show Snackbar
              await logAlertToFirestore('Acknowledgment', 'Acknowledgment received from contact.', latestMessage.body ?? 'No response body', contactPhone, contactName, location, driverStatus);
            } else if (latestMessage.body == '2') {
              print('Escalating...');
              await logAlertToFirestore('Escalation', 'Escalating alert for driver status: $driverStatus.', latestMessage.body ?? 'No response body', contactPhone, contactName, location, driverStatus);

              if (retryCount + 1 < emergencyContacts.length) {
                await sendAlert('Escalating alert', 'Escalating alert for driver status: $driverStatus.', emergencyContacts[retryCount + 1]);
                await checkAcknowledgmentWithRetries(context, emergencyContacts, retryCount + 1, alertSentTime, location, driverStatus);
              } else {
                print('No more contacts to escalate to.');
              }
            }
          } else {
            Future.delayed(Duration(seconds: 30), () {
              checkAcknowledgmentWithRetries(context, emergencyContacts, retryCount, alertSentTime, location, driverStatus);
            });
          }
        } else {
          print('Error: Message date is null.');
        }
      } else {
        Future.delayed(Duration(seconds: 30), () {
          checkAcknowledgmentWithRetries(context, emergencyContacts, retryCount, alertSentTime, location, driverStatus);
        });
      }
    } catch (e) {
      print('Error checking acknowledgment: $e');
    }
  }



  // Assess driver’s state and trigger alerts
  void assessDriverState(BuildContext context) async {
    List<String> states = ['drunk', 'drowsy', 'sober', 'awake'];
    String driverState = states[Random().nextInt(states.length)];

    print('Driver state detected: $driverState');

    String message;
    switch (driverState) {
      case 'drunk':
        message = 'Alert: Driver is potentially drunk!';
        break;
      case 'drowsy':
        message = 'Warning: Driver is drowsy and may fall asleep!';
        break;
      case 'awake':
      case 'sober':
        print('No alert sent. Driver is awake or sober.');
        return;
      default:
        message = 'An unknown condition has occurred.';
    }

    List<Map<String, String>> contacts = await fetchEmergencyContacts();
    if (contacts.isNotEmpty) {
      DateTime alertSentTime = DateTime.now();

      // Fetch location
      String location = await getCurrentLocationWithLogging();

      // Send alert
      await sendAlert('danger', message, contacts[0]); // Send to one contact

      // Check acknowledgment with retries
      await checkAcknowledgmentWithRetries(
          context, contacts, 0, alertSentTime, location, driverState);
    }
  }
  void showAcknowledgmentSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acknowledgment received!'),
          duration: Duration(seconds: 3),
        )
    );
  }
}

class AlertScreen extends StatelessWidget {
  final AlertGenerator _alertGenerator = AlertGenerator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Alert System'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _alertGenerator.assessDriverState(context);
          },
          child: Text('Assess Driver Status'),
        ),
      ),
    );
  }
}

