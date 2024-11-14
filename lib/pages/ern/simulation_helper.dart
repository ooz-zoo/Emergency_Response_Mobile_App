import 'dart:math';

class SimulationServiceHelper {
  static final List<String> conditions = ['awake/sober', 'drowsy', 'drunk']; // Updated condition names
  static double currentSafetyScore = 100.0; // Persistent safety score

  static Map<String, dynamic> simulateDriverCondition() {
    String driverCondition = conditions[Random().nextInt(conditions.length)];
    double safetyScore = calculateSafetyScore(driverCondition);
    DateTime timestamp = DateTime.now(); // Add timestamp here

    return {
      'condition': driverCondition,
      'safetyScore': safetyScore,
      'timestamp': timestamp, // Include timestamp in the returned data
    };
  }

  static double calculateSafetyScore(String condition) {
    switch (condition) {
      case "awake/sober":
        currentSafetyScore = min(currentSafetyScore + 3, 100); // Gradually increase towards 100
        break;
      case "drowsy":
        currentSafetyScore -= 10; // Subtract smaller value for drowsy
        break;
      case "drunk":
        currentSafetyScore -= 20; // Subtract smaller value for drunk
        break;
      default:
      // No change needed, keep the current safety score
        break;
    }

    // Ensure the safety score does not go below zero
    currentSafetyScore = max(currentSafetyScore, 0);

    return currentSafetyScore;
  }
}
