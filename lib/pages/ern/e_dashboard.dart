import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'e_alert.dart';
import 'hive_local_storage.dart';
import 'simulation_helper.dart';
import 'alert_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Import latlong2 for coordinates

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

// Assuming _currentPosition is already obtained like in your location file
LatLng? _currentPosition = LatLng(37.7749, -122.4194); // Dummy position, replace with real one

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


  List<double> dailyData = List.filled(
      24, 0.0); // Holds safetyScore for each time slot of the day
  List<double> weeklyData = List.filled(
      7, 0.0); // Holds safetyScore for each day of the week
  List<double> monthlyData = List.filled(12, 0.0); // New monthly data list

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        selectedTimeframe =
        _tabController!.index == 0 ? "Daily" : _tabController!.index == 1
            ? "Weekly"
            : "Monthly";
      });
    });
    fetchUsername();
    loadDriverConditions();
   // driverConditionBox = Hive.box<DriverCondition>('driver_conditions'); // Initialize the box
    HiveService.init();
    loadSafetyScore();
    // Get the current day name based on today's date
    String currentDayName = daysOfWeek[DateTime.now().weekday - 1];
    fetchPreviousDaySafetyScore(currentDayName);
    //checkStoredCondition();
    //loadPreviousCondition();
  }

  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference the document within the 'users' collection by the user ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'users').doc(user.uid).get();

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

      drowsinessMessage =
      "Condition: $driverCondition\nSafety Score: $safetyScore";

     // safetyScore = min(safetyScore, 10);
      //drowsinessMessage = "Condition: $driverCondition\nSafety Score: $safetyScore";

      int currentHour = DateTime
          .now()
          .hour;
      int slot = getTimeSlot(
          currentHour); // A separate function to get the correct slot
      print("Assigned Slot: $slot");

      // Safeguard against out-of-range slot assignment
      if (slot >= 0 && slot < dailyData.length) {
        dailyData[slot] =
            safetyScore; // Update daily data for the current time slot
      }

      // Update weekly and monthly data
      int currentDay = DateTime
          .now()
          .weekday;
      weeklyData[currentDay] = safetyScore; // Adjust for zero-indexed week
      int currentMonth = DateTime
          .now()
          .month - 1;
      monthlyData[currentMonth] = safetyScore;

      DateTime timestamp = DateTime.now();
      DriverCondition condition = DriverCondition(
        condition: driverCondition,
        safetyScore: safetyScore.toInt(),
        timestamp: timestamp,
      );

      // Print the condition before saving
      print("Generated DriverCondition: ${condition.toMap()}");

      // Save to Hive using HiveService
      HiveService.addDriverCondition(condition);

      // // Save to Firebase
      // FirebaseFirestore.instance.collection('driverConditions').add(condition.toMap());
      // hivestorage.addDriverCondition(condition);

      // Trigger the alert logic
      _driverStateService.assessDriverState(context, driverCondition);
    });
  }

  List<String> daysOfWeek = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday"
  ];

  String getPreviousDayName(String dayName) {
    int index = daysOfWeek.indexOf(dayName);
    if (index == -1) {
      throw ArgumentError("Invalid day name: $dayName");
    }

    int previousIndex = (index - 1 + daysOfWeek.length) % daysOfWeek.length;
    return daysOfWeek[previousIndex];
  }

  void fetchPreviousDaySafetyScore(String currentDay) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Get the previous day's name
      String previousDay = getPreviousDayName(currentDay);
      print("Current day: $currentDay, Previous day: $previousDay");

      // Reference the previous day's document in Firestore
      DocumentSnapshot<Map<String, dynamic>> prevDayDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('driverConditions')
          .doc('weeklyData')
          .collection('week1')
          .doc(previousDay) // Use the previousDay name to fetch the document
          .get();

      if (prevDayDoc.exists) {
        // Fetch the averageSafetyScore field instead of safetyScore
        int averageSafetyScore = prevDayDoc.data()?['averageSafetyScore'] ?? 0;
        print("Average safety score for $previousDay: $averageSafetyScore");

        setState(() {
          // Update weeklyData with the previous day's averageSafetyScore
          weeklyData[DateFormat('EEEE').parse(previousDay).weekday % 7] = averageSafetyScore.toDouble();
        });
      } else {
        print("No data found for the previous day.");
      }
    }
  }


  void loadSafetyScore() {
    Map<int, DriverCondition> lastRecordedValues = HiveService.getLastRecordedValuePerHour();
    int currentHour = DateTime.now().hour;
    setState(() {
      safetyScore = lastRecordedValues[currentHour]?.safetyScore.toDouble() ?? 0.0;
    });
    print("Loaded safety score: $safetyScore");
  }


  int getTimeSlot(int currentHour) {
    return currentHour; // For 9 PM to midnight
  }

  void loadDriverConditions() async {
    var box = await Hive.openBox<DriverCondition>('driver_conditions');
    List<DriverCondition> conditions = box.values.toList();

    setState(() {
      // Process the conditions and update your UI accordingly
    });
  }

  List<FlSpot> getGraphData(String timeframe) {
    if (timeframe == "Daily") {
      Map<int, DriverCondition> lastRecordedValues = HiveService.getLastRecordedValuePerHour();

      return List.generate(24, (index) {
        double score = lastRecordedValues[index]?.safetyScore.toDouble() ?? 0.0;
        return FlSpot(index.toDouble(), score);
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
        '12 AM',
        '1 AM',
        '2 AM',
        '3 AM',
        '4 AM',
        '5 AM',
        '6 AM',
        '7 AM',
        '8 AM',
        '9 AM',
        '10 AM',
        '11 AM',
        '12 PM',
        '1 PM',
        '2 PM',
        '3 PM',
        '4 PM',
        '5 PM',
        '6 PM',
        '7 PM',
        '8 PM',
        '9 PM',
        '10 PM',
        '11 PM'
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
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: customBlue.withOpacity(0.8)),
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
          TabBar(
            controller: _tabController,
            labelColor: customBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: customBlue,
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
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        if (value % 10 == 0) {
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
                      reservedSize: 27,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        List<String> labels = getXAxisLabels(selectedTimeframe);
                        if (selectedTimeframe == "Daily" && index % 4 == 0 && index < labels.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Transform.rotate(
                              angle: -pi / 2,
                              child: Text(
                                labels[index],
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        } else if ((selectedTimeframe == "Weekly" || selectedTimeframe == "Monthly") && index < labels.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              labels[index],
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0, // Set the minimum y-axis value
                maxY: 100, // Set the maximum y-axis value
                barGroups: getGraphData(selectedTimeframe).map((spot) {
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: customBlue,
                        width: 8,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              setState(() {
                simulationStarted = true;
                startSimulation();
              });
            },
            child: Text("Start Simulation"),
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Card(
                elevation: 4,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Recent Activities", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.person_add, color: Colors.green),
                        title: Text("New Emergency Contact Added"),
                        subtitle: Text("John Doe added as an emergency contact"),
                        trailing: Text("10:30 AM"),
                      ),
                      ListTile(
                        leading: Icon(Icons.warning, color: Colors.red),
                        title: Text("Incident Logged"),
                        subtitle: Text("Over-speeding incident logged at Main St."),
                        trailing: Text("11:00 AM"),
                      ),
                      ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.blue),
                        title: Text("Simulation Result"),
                        subtitle: Text("Simulation completed with optimal rest areas"),
                        trailing: Text("11:30 AM"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 250, // Adjust height as needed
                  padding: EdgeInsets.all(8),
                child: Center(
                child: Text("Map Placeholder", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 4,
                  child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(8),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text("Recommended Rest Areas", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("recommendedRestAreas", style: TextStyle(fontSize: 16)),
                    ]),
                   ),
                  )
            ],
          ),
        ],
      ),
    );
  }


}

