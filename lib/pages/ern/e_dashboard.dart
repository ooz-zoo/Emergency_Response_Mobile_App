import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'e_alert.dart';
import 'simulation_helper.dart';
import 'alert_helper.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}



class DriverCondition {
  String condition;
  int safetyScore;
  DateTime timestamp;

  DriverCondition({required this.condition, required this.safetyScore, required this.timestamp});

  // Convert the DriverCondition instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'safetyScore': safetyScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create a DriverCondition instance from a Map
  factory DriverCondition.fromMap(Map<String, dynamic> map) {
    return DriverCondition(
      condition: map['condition'],
      safetyScore: map['safetyScore'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Future<void> saveConditionLocally(DriverCondition condition, String key) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String jsonData = jsonEncode(condition.toMap());
//   await prefs.setString(key, jsonData);
//
//   // Print to confirm the data is saved
//   print("Condition saved locally: $jsonData");
// }

// Future<DriverCondition?> getConditionLocally(String key) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String? jsonData = prefs.getString(key);
//
//   // Print to check if data is found in local storage
//   print("Retrieved data: $jsonData");
//
//   if (jsonData != null) {
//     Map<String, dynamic> map = jsonDecode(jsonData);
//     return DriverCondition.fromMap(map);
//   }
//   return null;
// }

// Future<void> checkStoredCondition() async {
//   DriverCondition? storedCondition = await getConditionLocally('lastDriverCondition');
//   if (storedCondition != null) {
//     print("Persisted Condition: ${storedCondition.condition}, "
//         "Safety Score: ${storedCondition.safetyScore}, "
//         "Timestamp: ${storedCondition.timestamp}");
//   } else {
//     print("No stored condition found.");
//   }
// }

class DashboardScreen extends StatefulWidget {


  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String selectedTimeframe = "Daily";
  double safetyScore = 0.0;
  bool simulationStarted = false;
  String driverCondition = "";
  String drowsinessMessage = "";
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String username = "User"; // Default username

  //final List<String> conditions = ["awake", "Drunk", "Drowsy"];
  final DriverStateService _driverStateService = DriverStateService(); // Instantiate the shared service



  List<double> dailyData = List.filled(24, 0.0); // Holds safetyScore for each time slot of the day
  List<double> weeklyData = List.filled(7, 0.0); // Holds safetyScore for each day of the week
  List<double> monthlyData = List.filled(12, 0.0); // New monthly data list

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        selectedTimeframe = _tabController!.index == 0 ? "Daily" : _tabController!.index == 1 ? "Weekly" : "Monthly";
      });
    });
    fetchUsername();
    //checkStoredCondition();
    //loadPreviousCondition();
  }


  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference the document within the 'users' collection by the user ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      // If the document exists, set the username
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? "User";
        });
      }
    }
  }

  void startSimulation() {

    setState(() {
      var result = SimulationServiceHelper.simulateDriverCondition();
      String driverCondition = result['condition'];
      safetyScore = result['safetyScore'];

      drowsinessMessage = "Condition: $driverCondition\nSafety Score: $safetyScore";

      safetyScore = min(safetyScore, 10);
        //drowsinessMessage = "Condition: $driverCondition\nSafety Score: $safetyScore";

      int currentHour = DateTime.now().hour;
      int slot = getTimeSlot(currentHour); // A separate function to get the correct slot
      print("Assigned Slot: $slot");

      // Safeguard against out-of-range slot assignment
      if (slot >= 0 && slot < dailyData.length) {
        dailyData[slot] = safetyScore; // Update daily data for the current time slot
      }

      // Update weekly and monthly data
      int currentDay = DateTime.now().weekday;
      weeklyData[currentDay] = safetyScore; // Adjust for zero-indexed week
      int currentMonth = DateTime.now().month - 1;
      monthlyData[currentMonth] = safetyScore;

      DateTime timestamp = DateTime.now();
      DriverCondition condition = DriverCondition(
        condition: driverCondition,
        safetyScore: safetyScore.toInt(),
        timestamp: timestamp,
      );

      //saveConditionLocally(condition, "previousCondition");

      // Trigger the alert logic
      _driverStateService.assessDriverState(context, driverCondition);
    });
  }

  int getTimeSlot(int currentHour) {
    return currentHour; // For 9 PM to midnight
  }

  // void loadPreviousCondition() async {
  // DriverCondition? previousCondition = await getConditionLocally("previousCondition");
  //
  // if (previousCondition != null) {
  // print("Previous Condition: ${previousCondition.condition}");
  // print("Safety Score: ${previousCondition.safetyScore}");
  // print("Timestamp: ${previousCondition.timestamp}");
  // } else {
  // print("No previous condition found.");
  // }
  // }

  List<FlSpot> getGraphData(String timeframe) {
    if (!simulationStarted) {
      return List.generate(24, (index) => FlSpot(index.toDouble(), 0));
    }

    if (timeframe == "Daily") {
      return List.generate(24, (index) {
        return FlSpot(index.toDouble(), dailyData[index]);
      });
    } else if (timeframe == "Weekly") {
      return List.generate(7, (index) {
        return FlSpot(index.toDouble(), weeklyData[index]);
      });
    } else if (timeframe == "Monthly") {
      return List.generate(12, (index) {
        return FlSpot(index.toDouble(), monthlyData[index]);
      });
    }

    return List.generate(24, (index) => FlSpot(index.toDouble(), 0));
  }

  List<String> getXAxisLabels(String timeframe) {
    if (timeframe == "Daily") {
      // Generate labels for every 3 hours
      return [
        '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM', '7 AM', '8 AM', '9 AM', '10 AM', '11 AM', '12 PM',
        '1 PM', '2 PM', '3 PM', '4 PM', '5 PM', '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM'
      ];
    } else if (timeframe == "Weekly") {
      return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    } else if (timeframe == "Monthly") {
      return List.generate(12, (index) => (index + 1).toString());
    }
    return [];
  }

  Color customBlue = const Color(0xFF007BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Emergency Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              decoration: BoxDecoration(color: customBlue),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.emergency_share_outlined),
              title: Text('Emergency contacts'),
              onTap: () => Navigator.pushNamed(context, "/contact_list"),
            ),
            ListTile(
              leading: Icon(Icons.history_outlined),
              title: Text('Logs'),
              onTap: () => Navigator.pushNamed(context, "/logs"),
            ),
            ListTile(
              leading: Icon(Icons.add_ic_call_outlined),
              title: Text('Add E-contact'),
              onTap: () => Navigator.pushNamed(context, "/contact_form"),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => Navigator.pushNamed(context, "/login"),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                SizedBox(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Welcome back, $username", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.8)),
                      child: Center(
                        child: Text(
                          safetyScore.toStringAsFixed(1),
                          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: "Daily"),
                        Tab(text: "Weekly"),
                        Tab(text: "Monthly"),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 250,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 5,
                                getTitlesWidget: (value, meta) {
                                  if (value == 10 || value == 7 || value == 5 || value == 3 || value == 0) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    );
                                  }
                                  return Container();
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  List<String> labels = getXAxisLabels(selectedTimeframe);
                                  // Show labels at appropriate intervals based on the timeframe
                                  if (selectedTimeframe == "Daily") {
                                    if (index % 4 == 0 && index < labels.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Transform.rotate(
                                          angle: -pi / 2, // Rotate the text to be vertical
                                          child: Text(
                                            labels[index],
                                            style: TextStyle(color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
                                  } else if (selectedTimeframe == "Weekly" || selectedTimeframe == "Monthly") {
                                    if (index < labels.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          labels[index],
                                          style: TextStyle(color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                  }
                                  return Container();
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false), // Disable top titles
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false), // Disable right titles
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: selectedTimeframe == "Daily" ? 23 : getXAxisLabels(selectedTimeframe).length - 1,
                          minY: -1.5,
                          maxY: 10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: getGraphData(selectedTimeframe),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 4,
                              belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      simulationStarted = true;
                      startSimulation(); // Start simulation to generate data
                    });
                  },
                  child: Text("Start Simulation"),
                ),
                SizedBox(height: 20),
                //Text(drowsinessMessage, style: TextStyle(fontSize: 18)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        // Left Card (Driver's Condition)
          Card(
            elevation: 4,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 100,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Driver Condition", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(driverCondition, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          // Timestamp Card
          Card(
            elevation: 4,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 100,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Timestamp", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("timestamp", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
                SizedBox(height: 16),
                // Recommended Rest Areas Card
                Card(
                  elevation: 4,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 150,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Recommended Rest Areas", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("recommendedRestAreas", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}