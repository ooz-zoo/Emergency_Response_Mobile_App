import 'package:flutter/material.dart';
import 'hive_service.dart';
import 'firebase_helper_service.dart';
import 'hive_local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestFirebaseStorage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Firebase Storage'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await calculateAndStoreDailyAverage();
          },
          child: Text('Send Daily Average to Firebase'),
        ),
      ),
    );
  }

  Future<void> calculateAndStoreDailyAverage() async {
    double averageSafetyScore = await HiveService.calculateDailyAverageSafetyScore();
    String userId = getCurrentUserId(); // Get the currently logged-in user ID
    if (userId.isNotEmpty) {
      String day = getCurrentDay(); // Implement logic to get the current day
      await FirebaseService.storeDailyAverage(userId, day, averageSafetyScore);
    } else {
      print("No user is currently logged in.");
    }
  }

  String getCurrentDay() {
    // Implement logic to get the current day as a string, e.g., "monday"
    DateTime now = DateTime.now();
    List<String> days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
    return days[now.weekday % 7];
  }

  String getCurrentUserId() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }
}

void main() {
  runApp(MaterialApp(
    home: TestFirebaseStorage(),
  ));
}
