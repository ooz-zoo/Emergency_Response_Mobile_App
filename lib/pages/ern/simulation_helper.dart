// SimulationServiceHelper.dart
import 'dart:math';

class SimulationServiceHelper {
  static final List<String> conditions = ['awake/sober', 'drowsy', 'drunk']; // Updated condition names

  static Map<String, dynamic> simulateDriverCondition() {
    String driverCondition = conditions[Random().nextInt(conditions.length)];
    double safetyScore;

    switch (driverCondition) {
      case "awake/sober":
        safetyScore = 7 + Random().nextDouble() * 3; // Between 7 and 10
        break;
      case "drowsy":
        safetyScore = 4 + Random().nextDouble() * 2; // Between 4 and 6
        break;
      case "drunk":
        safetyScore = Random().nextDouble() * 3; // Between 0 and 3
        break;
      default:
        safetyScore = 0;
    }

    safetyScore = min(safetyScore, 10);

    return {
      'condition': driverCondition,
      'safetyScore': safetyScore,
    };
  }
}
