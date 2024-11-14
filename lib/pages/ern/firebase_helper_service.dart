import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<void> storeDailyAverage(String userId, String day, double averageSafetyScore) async {
    final week = getCurrentWeek();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('driverConditions')
        .doc('weeklyData')
        .collection(week)
        .doc(day)
        .set({
      'day': day,
      'averageSafetyScore': averageSafetyScore
    }, SetOptions(merge: true));
    print("Stored daily average for $day: $averageSafetyScore");
  }

  static String getCurrentWeek() {
    // Implement logic to get the current week identifier
    // For example, "week1", "week2", etc.
    return "week1"; // Placeholder
  }
}
