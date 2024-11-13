import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'e_dashboard.dart';


part 'hive_service.g.dart';

@HiveType(typeId: 0)
class DriverCondition extends HiveObject {
  @HiveField(0)
  String condition;

  @HiveField(1)
  int safetyScore;

  @HiveField(2)
  DateTime timestamp;

  DriverCondition({required this.condition, required this.safetyScore, required this.timestamp});
}
