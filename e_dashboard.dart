import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}

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

  final List<String> conditions = ["Sober", "Awake", "Drunk", "Drowsy"];

  List<double> dailyData = List.filled(4, 0.0); // Holds safetyScore for each time slot of the day
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
  }

  void startSimulation() {
    setState(() {
      // Define percentage thresholds for each condition
      Map<String, int> thresholds = {
        "Sober": 90,   // Sober drivers start with a high percentage
        "Awake": 70,   // Awake drivers between 70-89% perceived alertness
        "Drowsy": 40,  // Drowsy drivers between 40-69%
        "Drunk": 10    // Drunk drivers between 0-39%
      };

      // Select random driver condition
      driverCondition = conditions[Random().nextInt(conditions.length)];

      // Generate a random percentage and map to safety score based on thresholds
      int percentage = Random().nextInt(101); // Random percentage from 0 to 100

      if (percentage >= thresholds["Sober"]!) {
        safetyScore = 10;  // Sober: full score
      } else if (percentage >= thresholds["Awake"]!) {
        safetyScore = 9;  // Awake: high score
      } else if (percentage >= thresholds["Drowsy"]!) {
        safetyScore = 5 + (percentage - 40) / 30 * 4; // Scaled score for drowsy
      } else {
        safetyScore = percentage / 10; // Drunk: lower range scaled to 0-3
      }

      // Update message and re-render
      drowsinessMessage = "Condition: $driverCondition\nAlertness Level: $percentage%";

      // Update daily data
      DateTime now = DateTime.now();
      int currentHour = now.hour;

      // Determine the slot based on current hour
      int slot;
      if (currentHour >= 0 && currentHour < 6) {
        slot = 0; // 12 AM - 6 AM
      } else if (currentHour >= 6 && currentHour < 12) {
        slot = 1; // 6 AM - 12 PM
      } else if (currentHour >= 12 && currentHour < 18) {
        slot = 2; // 12 PM - 6 PM
      } else {
        slot = 3; // 6 PM - 12 AM
      }

      dailyData[slot] = safetyScore; // Store the safety score for the current time slot
    });
  }


  List<FlSpot> getGraphData(String timeframe) {
    if (!simulationStarted) {
      // Return zeroed values if simulation hasn't started
      return List.generate(12, (index) => FlSpot(index.toDouble(), 0)); // Change 4 to 12 for monthly
    }

    if (timeframe == "Daily") {
      DateTime now = DateTime.now();
      int currentHour = now.hour;

      // Determine the slot based on current hour
      int slot;
      if (currentHour >= 0 && currentHour < 6) {
        slot = 0; // 12 AM - 6 AM
      } else if (currentHour >= 6 && currentHour < 12) {
        slot = 1; // 6 AM - 12 PM
      } else if (currentHour >= 12 && currentHour < 18) {
        slot = 2; // 12 PM - 6 PM
      } else {
        slot = 3; // 6 PM - 12 AM
      }

      // Show safety score for the current time slot
      return List.generate(4, (index) {
        return FlSpot(index.toDouble(), index == slot ? safetyScore : 0);
      });
    } else if (timeframe == "Weekly") {
      // Show safety score for the week based on the stored weeklyData
      return List.generate(7, (index) {
        return FlSpot(index.toDouble(), weeklyData[index]);
      });
    } else if (timeframe == "Monthly") {
      // Show safety score for the months based on the stored monthlyData
      return List.generate(12, (index) {
        return FlSpot(index.toDouble(), monthlyData[index]);
      });
    }

    // Default case, should not be reached
    return List.generate(12, (index) => FlSpot(index.toDouble(), 0));
  }


  List<String> getXAxisLabels(String timeframe) {
    if (timeframe == "Daily") {
      return ["6 AM", "9 AM", "12 PM", "3 PM", "6 PM", "9 PM", "12 AM"];
    } else if (timeframe == "Weekly") {
      return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    } else if (timeframe == "Monthly") {
      return List.generate(12, (index) => (index + 1).toString());
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Statistics'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => Navigator.pop(context),
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
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Welcome back, User!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      width: 80,
                      height: 80,
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
                                  return (index % 2 == 0 && index < labels.length)
                                      ? Text(labels[index], style: TextStyle(color: Colors.grey))
                                      : Container();
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
                          maxX: getXAxisLabels(selectedTimeframe).length - 1,
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
                Text(drowsinessMessage, style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
