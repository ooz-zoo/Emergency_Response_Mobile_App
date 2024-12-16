import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';
import 'package:journeyai/pages/ern/hive_local_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_test/hive_test.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';
import 'package:journeyai/pages/ern/hive_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter test binding

  group('HiveService Tests', () {
    setUp(() async {
      await setUpTestHive();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DriverConditionAdapter());
      }
      await Hive.openBox<DriverCondition>(HiveService.boxName);
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test('Add Driver Condition', () async {
      final condition = DriverCondition(
        timestamp: DateTime(2024, 11, 21, 10), // Example timestamp
        safetyScore: 85,
        condition: '',
      );
      await HiveService.addDriverCondition(condition);
      final box = Hive.box<DriverCondition>(HiveService.boxName);
      final storedCondition = box.get(condition.timestamp.hour);
      expect(storedCondition?.safetyScore, condition.safetyScore);
    });



    test('Calculate daily average safety score', () async {
      final conditions = [
        DriverCondition(timestamp: DateTime(2024, 11, 21, 10), safetyScore: 80, condition: ''),
        DriverCondition(timestamp: DateTime(2024, 11, 21, 15), safetyScore: 90, condition: ''),
      ];

      for (var condition in conditions) {
        await HiveService.addDriverCondition(condition);
      }

      final averageScore = await HiveService.calculateDailyAverageSafetyScore();

      expect(averageScore, 85.0, reason: "Average safety score should be correctly calculated.");
    });

    test('Retrieve last recorded safety score', () async {
      final conditions = [
        DriverCondition(timestamp: DateTime(2024, 11, 21, 10), safetyScore: 70, condition: ''),
        DriverCondition(timestamp: DateTime(2024, 11, 21, 23), safetyScore: 90, condition: ''),
      ];

      for (var condition in conditions) {
        await HiveService.addDriverCondition(condition);
      }

      final lastScore = await HiveService.getLastRecordedSafetyScore();

      expect(lastScore, 90.0, reason: "Last recorded safety score should match the latest entry.");
    });
  });
}



