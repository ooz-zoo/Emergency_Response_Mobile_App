import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class FirebaseApi{
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');
   // FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received: ${message.notification?.title}');
    });
  }
}


// Future<void> handleBackgroundMessage(RemoteMessage message) async {
//   print('Title: ${message.notification?.title}');
//   print('Body: ${message.notification?.body}');
//   print('Payload: ${message.data}');
// }