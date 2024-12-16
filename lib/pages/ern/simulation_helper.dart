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








// import 'dart:math';
// import 'dart:io';
// import 'dart:convert';
// import 'package:journeyai/pages/ern/e_dashboard.dart';
// import 'package:path_provider/path_provider.dart';
// import 'file4.dart'; // Import File 4
//
// class SimulationServiceHelper {
//   static final List<String> conditions = ['Sober/Awake', 'Drowsy', 'Drunk'];
//   static double currentSafetyScore = 100.0;
//   static String currentDriverCondition = '';
//
//   static void processDriverConditionDirectly(String driverCondition) async {
//     try {
//       print('Starting processDriverConditionDirectly'); // Debugging statement
//       currentDriverCondition = driverCondition;
//
//       double safetyScore = calculateSafetyScore(driverCondition);
//       DateTime timestamp = DateTime.now();
//
//       print('Driver Condition: $driverCondition');
//       print('Safety Score: $safetyScore');
//       print('Timestamp: $timestamp');
//
//       final processedData = {
//         'condition': currentDriverCondition,
//         'safetyScore': safetyScore,
//         'timestamp': timestamp.toIso8601String(),
//       };
//
//       final directory = await getApplicationDocumentsDirectory();
//       final processedFile = File('${directory.path}/processed_data.json');
//       await processedFile.writeAsString(jsonEncode(processedData), mode: FileMode.write); // Overwrite the file
//       print('Processed Data: ${jsonEncode(processedData)}'); // Print the JSON data to the console
//
//       // Pass the entire processedData JSON object to File 4
//       DashboardScreen.processDataFromFile2(processedData);
//     } catch (e) {
//       print('Error processing driver condition: $e'); // Print any errors
//     }
//   }
//
//   static double calculateSafetyScore(String condition) {
//     switch (condition) {
//       case 'Sober/Awake':
//         currentSafetyScore = min(currentSafetyScore + 3, 100);
//         break;
//       case 'Drowsy':
//         currentSafetyScore -= 10;
//         break;
//       case 'Drunk':
//         currentSafetyScore -= 20;
//         break;
//       default:
//         break;
//     }
//
//     currentSafetyScore = max(currentSafetyScore, 0);
//     return currentSafetyScore;
//   }
// }
//
