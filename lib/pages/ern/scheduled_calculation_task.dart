import 'package:cron/cron.dart';
import 'hive_service.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_local_storage.dart';
import 'firebase_helper_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  final cron = Cron();

  cron.schedule(Schedule.parse('55 23 * * *'), () async {
    double averageSafetyScore = await HiveService.calculateDailyAverageSafetyScore();
    String userId = getCurrentUserId(); // Get the currently logged-in user ID
    if (userId.isNotEmpty) {
      String day = getCurrentDay(); // Implement logic to get the current day
      await FirebaseService.storeDailyAverage(userId, day, averageSafetyScore);
    } else {
      print("No user is currently logged in.");
    }
  });

  // Other initialization code...
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
