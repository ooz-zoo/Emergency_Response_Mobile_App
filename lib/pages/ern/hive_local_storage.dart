import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'e_dashboard.dart';
import 'firebase_helper_service.dart'; // Import your Firebase service

part 'hive_local_storage.g.dart';

class HiveService {
  static const String boxName = "driverConditions";

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    Hive.registerAdapter(DriverConditionAdapter());
    await Hive.openBox<DriverCondition>(boxName);
    print("Hive initialized and box opened.");
  }

  static Future<void> addDriverCondition(DriverCondition condition) async {
    final box = Hive.box<DriverCondition>(boxName);
    int slot = condition.timestamp.hour; // Use the hour of the timestamp as the slot
    await box.put(slot, condition); // Store the condition in the correct slot
    print("DriverCondition added to Hive: ${condition.toMap()} at slot $slot");
  }

  static Map<int, DriverCondition> getLastRecordedValuePerHour() {
    final box = Hive.box<DriverCondition>(boxName);
    Map<int, DriverCondition> lastRecordedPerHour = {};

    for (int hour = 0; hour < 24; hour++) {
      DriverCondition? condition = box.get(hour);
      if (condition != null) {
        lastRecordedPerHour[hour] = condition;
      }
    }

    print("Last recorded values per hour: ${lastRecordedPerHour.map((key, value) => MapEntry(key, value.toMap()))}");
    return lastRecordedPerHour;
  }

  static Future<double> getLastRecordedSafetyScore() async {
    final box = Hive.box<DriverCondition>(boxName);
    DriverCondition? lastCondition;
    for (int hour = 23; hour >= 0; hour--) {
      lastCondition = box.get(hour);
      if (lastCondition != null) {
        break;
      }
    }
    double lastSafetyScore = lastCondition?.safetyScore.toDouble() ?? 0.0;
    print("Last recorded safety score: $lastSafetyScore");
    return lastSafetyScore;
  }

  static Future<double> calculateDailyAverageSafetyScore() async {
    final box = Hive.box<DriverCondition>(boxName);
    double totalScore = 0;
    int count = 0;

    for (int hour = 0; hour < 24; hour++) {
      DriverCondition? condition = box.get(hour);
      if (condition != null) {
        totalScore += condition.safetyScore;
        count++;
      }
    }

    double averageScore = count > 0 ? totalScore / count : 0.0;
    print("Calculated daily average safety score: $averageScore");
    return averageScore;
  }
}
