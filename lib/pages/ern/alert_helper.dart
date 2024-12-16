// driverStateService.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:telephony_sms_handler/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class DriverStateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Telephony telephony = Telephony.instance;

  // Initial location for the map
  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;

  //void setCurrentPosition(LatLng position, Function(LatLng) updateState) { _currentPosition = position; updateState(position);}

  String getCurrentUserId() {
    User? user = _auth.currentUser;
    return user != null ? user.uid : '';
  }


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

  Future<String> logAlertToFirestore(String alertType, String message,
      String response, String contactID, String contactName, String location,
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


  Future<void> sendAlert(String alertType, String message,
      Map<String, String> contact) async {
    String location = await getCurrentLocationWithLogging();
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

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );


        _currentPosition = LatLng(position.latitude, position.longitude);
        //_coordinates = 'Coordinates: ${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E';
        //_isLoading = true;


      String street = placemarks[0].street ?? 'Unknown street';
      String city = placemarks[0].locality ?? 'Unknown city';
      //String mapUrl = 'https://goo.gl/maps/?q=${position.latitude},${position
          //.longitude}';
      String longUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      String mapUrl = await shortenUrl(longUrl);

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

  Future<String> shortenUrl(String longUrl) async {
    final response = await http.get(Uri.parse('https://tinyurl.com/api-create.php?url=$longUrl'));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to shorten URL');
    }
  }

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
                await sendAlert('Escalating alert', 'Escalating alert for driver status: Driver is: $driverStatus.', emergencyContacts[retryCount + 1]);
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

  Future<void> assessDriverState(BuildContext context,
      String driverCondition) async {
    String message;
    switch (driverCondition) {
      case 'Drunk':
        message = 'Alert: Driver is potentially drunk!';
        break;
      case 'Drowsy':
        message = 'Warning: Driver is drowsy and may fall asleep!';
        break;
      case 'Sober/Awake':
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
          context, contacts, 0, alertSentTime, location, driverCondition);
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

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
);

