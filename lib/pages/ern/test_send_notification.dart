import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:geolocator/geolocator.dart';

class PushNotificationService extends StatelessWidget {
  static Future<String> getAccessToken() async {
    final serviceAccountJson =
    {
      "type": "service_account",
      "project_id": "emergencyresponse-8e3cd",
      "private_key_id": "d4d17d36f8fb82a0415aa782259b50cecc796ef3",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDS2GmjuXt1HBA+\nRNPL2K/Q+5sWTCOiP5sxxKMaXROBDfRGDQ9P1Ms3w88nHczG65qaQ0G3rAm2FPOu\nNJqJfSDIGNZvaphcLYAd12S47uGyH9R4MwJ1zOqj6Jy3y46F0ezWBzXKw4HSecry\nM1y/QaUPS+wcV8FGqG1/3HeG0BnKbvJkRV0F3w1w5MnsQsev6IqcCZjEkZzUrdzi\nNdQAxrBVzdrIgOtKt8ht4RiA+JxpY9HaDCaSYE6GwiRwsUDVIDmO5iSlQfMdQTPG\nTYJscpyIcxkGwHpqq4B+zcQzlcqw36StHJ/SsFRVTMXTlHEvAQB2crd2HcTgOg7z\nGZbo1Ez5AgMBAAECggEABA6P8cuG2ZkBowEWBi0ULPQ6ZrJuWRfaN5nt/Xre/jOz\niImFyuZwRpFo8fq7zvQHlIJIyGzx/uPmUGrIsm6K6+62aYxmhBeICIr1cC2AgDnm\nj62DlZqsxRybr1mmU2LXqMKYwV8Dp3YadpCQb0mnEGVIlL8HhAGHodcvIZPtexyg\nbFRWMa5GHYbbHnQOvRxRqgnW9zV/OmsPCR9jm5odQPNOSJFeIN1MTqWOhK8wKHGx\ndp5RpyZ7Q75PSYfIs9u15jpEi2PvgCxH3dTlIGzR1S8xWGQI6vvDZIg3STwjT8eY\nMpm/Au/m+3QAFo/PNMxg2cZMXxgKwfCzLRYpAlLk5QKBgQD6F/NstkYIdhvQ+Y5b\nGrvZKbh4rRNqvSuHl7foxlYAYwV8cDCMgbb5b0Iql50qKkpdMqg6Liqxz7/ewpBR\ni4msCNTQx7b8A39yZzn0BsflE9VziDtL931GQZhgjr5DoA8lrQxpd+pV+L8KBcEx\nUmJpNbzck5RfRkAKZzI6iH8pPwKBgQDX0yt2f9HnlUi9Zv7kH545MKQoM9InjWbV\njwYyFPBpfVPKk6op9FyJK0+4eFabIHl/9Zg+7DN/b2543z5TCin9ZY02S3qLE04H\nl1wKX5Zc6SPvEdSzN48xCyTHb1z/4Bw5h7AQDKF3sQLDM45FoDSwZTj42e0bTVkB\nI3yObCCDxwKBgDqRqVxoQ3Zv0ovaJdCILj3pW15HiiiRLMSQb22AJVvp1LsTuwrs\nxeEcgS5gW1oolUnGN0eI0E7cDF8qyYmPWCqF1vEeFGhomUw9iIDxpZasUmzAFsLv\nrtLpQbo7M6u6rFFyeVmpz6NaocLDHj9iv9FL2HL/zNuTJCRLjqPOm5kZAoGBAJfw\nyHZiQiohRNZifiunvsJQZiEPanIB8FWEnT4A08fQPX8uOevTZpoC7drWjVIkqKTX\nB9m0fATJNCLQN5ZKX4lPRvzkYl8qthJOErQS206Jq4yRJwcMpDhIuhnVYsmYwwYV\nanPCEKKs8V7vGsgVo0JT4KoA8hX4fCJ7EyNJKBLdAoGBAL3PZdXQR83HqW8o84Kx\nLllWb4fVUeApu8Dwc9cyDGuQvFDoP67Z/MCZdCXd1MTVzd3e9SL97H+7hMbDihax\nerdi4AOeQ0oN84HqhQfbU0elBc1pA/q7RdGlB1KyojP4L/YMBxXWhM2umH6ZNHew\nxK7fad66c7b7jOGMvuwIku7Y\n-----END PRIVATE KEY-----\n",
      "client_email": "emergency-response-sacc@emergencyresponse-8e3cd.iam.gserviceaccount.com",
      "client_id": "108164869373757946297",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/emergency-response-sacc%40emergencyresponse-8e3cd.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    final client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    final credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );

    client.close();
    return credentials.accessToken.data;
  }


  Future<void> sendNotification(String driverCondition, Position position, String username, String timestamp, String driverId) async {
      final String serverAccessTokenkey = await getAccessToken();
      String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/emergencyresponse-8e3cd/messages:send';

      // Reactjs web app dashboard fcm token
      final String deviceToken = 'eIxrJlpAr4l5dnnMeEM8gV:APA91bGjkKpjk5dGQYRlI9kSEVclZBbqATCCzKNygcEzW5AwdgDs3mnwR4ZBtkG5ApwyiYvEMwwEQyE9QCh5X7PP6JyLlGZSNAAsZxsYcOC-HDw4-LsQPlc';

      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': "Notification Testing",
            'body': driverCondition
          },
          'data': {
            'latitude' : position.latitude.toString(),
            'longitude' : position.longitude.toString(),
            'username' : username,
            'timestamp': timestamp,
            'driverId' : driverId
          }
        }
      };

      final http.Response response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>
        {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessTokenkey'
        },
        body: jsonEncode(message)
        ,);

      if (response.statusCode == 200) {
        print("Notification sent successfully");
      }
      else {
        print("Notification sent: ${response.statusCode}");
      }
    }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    //throw UnimplementedError();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('FCM Notification Test'),
        ),
        body: Center(
          child: ElevatedButton(
              onPressed: () async{
                //await sendNotification(context);
              },
                child: Text('Send Notification'),
              ),
        ),
      ),
    );
  }
  }
