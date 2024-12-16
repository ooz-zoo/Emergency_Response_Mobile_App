import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:journeyai/pages/ern/test_send_notification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hive_local_storage.dart';

import 'alert_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart'; // Import latlong2 for coordinates
import 'package:http/http.dart' as http;
import 'package:journeyai/pages/ern/firebase_user.dart';

import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(
        detectedCondition: 'Unknown',  // This part stays as it is
        detectedTime: DateTime.now(),       // Add the current timestamp here
      ),
    );
  }
}

class DriverCondition {
  final String condition;
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

class DashboardScreen extends StatefulWidget {
  final String detectedCondition;
  final DateTime detectedTime;

  DashboardScreen({Key? key, required this.detectedCondition, required this.detectedTime}) : super(key: key);


  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String selectedTimeframe = "Daily";
  double safetyScore = 0.0;
  bool simulationStarted = false;
  //String driverCondition = "";
  String drowsinessMessage = "";
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String username = "User"; // Default username
  double previousDaySafetyScore = 0.0;
  List<double> weeklyScores = [];
  static double currentSafetyScore = 100.0;
  //String? previousCondition;
  final PopupController _popupController = PopupController();


  final DriverStateService _driverStateService = DriverStateService(); // Instantiate the shared service
  LatLng? _currentPosition;

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
    loadDriverConditions();
    HiveService.init();
    loadSafetyScore();
    _fetchCurrentPosition();
    fetchWeeklySafetyScores();
    if (DateTime.now().difference(widget.detectedTime).inSeconds < 30) {
      // If the condition is recent, calculate the safety score
      calculateSafetyScore(widget.detectedCondition);
    } else {
      // If the condition is outdated, do nothing
      print("Condition is outdated. No safety score calculated.");
    }
    fetchMonthlySafetyScores();
  }

 // void calculateSafetyScore(String condition) { switch (condition) { case "awake/sober": safetyScore = min(safetyScore + 3, 100); break; case "drowsy": safetyScore -= 10; break; case "drunk": safetyScore -= 20; break; default: break; } safetyScore = max(safetyScore, 0); setState(() {}); }

  Future<void> _fetchCurrentPosition() async {
    await _driverStateService.getCurrentLocationWithLogging();

    setState(() {
      _currentPosition = _driverStateService.currentPosition;
    });
    _getNearbyAmenities();
  }

  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? "User";
        });
      }
    }
  }

  void calculateSafetyScore(String condition) {
    print("Calculating safety score for condition: $condition"); // Debugging
    switch (condition) {
      case "Sober/Awake":
        currentSafetyScore = min(currentSafetyScore + 3, 100);
        break;
      case "Drowsy":
        currentSafetyScore -= 10;
        break;
      case "Drunk":
        currentSafetyScore -= 20;
        break;
      default:
        break;
    }

    currentSafetyScore = max(currentSafetyScore, 0); // Ensure it doesn't go below 0
    safetyScore = currentSafetyScore; // Update the instance variable
    print("Calculated Safety Score: $safetyScore"); // Debugging
    setState(() {});
  }



  Future<void> startSimulation() async {
    String driverCondition = widget.detectedCondition;

    print("condition received: $driverCondition");
    print("safetyscore received: $safetyScore");

    setState(() {

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
      weeklyData[currentDay % 7] = safetyScore; // Adjust for zero-indexed week
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
      print('Driver condition detected: $driverCondition');
    });

    String username = await getUsername();

    // Debugging: Print driverCondition after setState
    print("Driver Condition after setState: $driverCondition");
    // Get the current location
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print('location sent: $position');
    print('Driver condition received: $driverCondition');

    User? user = FirebaseAuth.instance.currentUser;
    String driverId = user?.uid ?? 'unknown';

    String timestamp = DateTime.now().toIso8601String();

    //Send the notification
    final pushNotificationService = PushNotificationService();
    await pushNotificationService.sendNotification(driverCondition, position, username, timestamp, driverId);
  }

  void loadSafetyScore() {
    Map<int, DriverCondition> lastRecordedValues = HiveService.getLastRecordedValuePerHour();
    int currentHour = DateTime.now().hour;

    setState(() {
      // Load the safety score from Hive, or default to 100.0 if not found
      safetyScore = lastRecordedValues[currentHour]?.safetyScore.toDouble() ?? 100.0; // Change this line
      currentSafetyScore = safetyScore; // Ensure currentSafetyScore is also set
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

  Future<void> fetchWeeklySafetyScores() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // List of weekdays to match Firestore document names
        List<String> weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];

        // Get the current day index (0-based for Sunday to Saturday)
        //int currentDayIndex = DateTime.now().weekday - 1; // Monday=0, Sunday=6

        // Fetch safety scores for the past week
        List<double> fetchedScores = [];

        for (int i = 0; i < 7; i++) {
          String day = weekdays[i];

          // Get the document reference for each day (from Sunday to Saturday)
          DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('driverConditions')
              .doc('weeklyData')
              .collection('week1')
              .doc(day)
              .get();

          // If the document exists, fetch and store the safety score
          if (docSnapshot.exists) {
            double safetyScore = (docSnapshot['averageSafetyScore'] as num).toDouble();
            fetchedScores.add(safetyScore);
          } else {
            fetchedScores.add(-1.0); // Mark as -1 or any placeholder value to indicate no data (this won't affect the graph)
          }
        }

        setState(() {
          weeklyScores = fetchedScores; // Store fetched scores to use in graph plotting
        });
      }
    } catch (e) {
      print('Error fetching weekly safety scores: $e');
    }
  }

  List<FlSpot> getGraphData(String timeframe) {
    if (timeframe == "Daily") {
      Map<int, DriverCondition> lastRecordedValues = HiveService.getLastRecordedValuePerHour();

      return List.generate(24, (index) {
        double score = lastRecordedValues[index]?.safetyScore.toDouble() ?? 0.0;
        return FlSpot(index.toDouble(), score);
      });
    } else if (timeframe == "Weekly") {
      int currentDayIndex = DateTime.now().weekday-1; // 0-based index for the current day
      int previousDayIndex = (currentDayIndex - 1) % 7; // Previous day index

      return List.generate(7, (index) {
        double safetyScore;

        if (index == previousDayIndex) {
          safetyScore = previousDaySafetyScore; // Plot previous day's safety score
        } else if (index < weeklyScores.length && weeklyScores[index] != -1.0) {
          // If data is available, plot it
          safetyScore = weeklyScores[index]; // Plot regular weekly data for past days
        } else {
          // For days with no data or future days, keep them unchanged (they will not affect the graph)
          safetyScore = weeklyData[index]; // Plot the original weekly data (don't use default value)
        }

        return FlSpot(index.toDouble(), safetyScore);
      });
    } else if (timeframe == "Monthly") {
      return List.generate(12, (index) {
        double safetyScore;

        if (monthlyData[index] != -1.0) {
          // If data is available, plot it
          safetyScore = monthlyData[index]; // Plot regular monthly data
        } else {
          // For months with no data, you can choose to plot a default value (e.g., 0.0)
          safetyScore = 0.0; // Or keep it unchanged, depending on your needs
        }

        return FlSpot(index.toDouble(), safetyScore);
      });
    }

    return List.generate(24, (index) => FlSpot(index.toDouble(), 0));
  }

  Future<void> fetchMonthlySafetyScores() async {
    try {
      User? user = FirebaseAuth.instance.currentUser ;
      if (user != null) {
        // List of months to match Firestore document names
        List<String> months = [
          "january", "february", "march", "april", "may", "june",
          "july", "august", "september", "october", "november", "december"
        ];

        // Fetch safety scores for the past 12 months
        List<double> fetchedScores = [];

        for (int i = 0; i < 12; i++) {
          String month = months[i];

          // Get the document reference for each month
          DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('driverConditions')
              .doc('monthlyData')
              .collection('monthlyData')
              .doc(month)
              .get();

          // If the document exists, fetch and store the safety score
          if (docSnapshot.exists) {
            double safetyScore = (docSnapshot['averageSafetyScore'] as num).toDouble();
            fetchedScores.add(safetyScore);
          } else {
            fetchedScores.add(-1.0); // Mark as -1 or any placeholder value to indicate no data
          }
        }

        setState(() {
          monthlyData = fetchedScores; // Store fetched scores to use in graph plotting
        });
      }
    } catch (e) {
      print('Error fetching monthly safety scores: $e');
    }
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

  Future<String> _shortenUrl(String longUrl) async { final response = await http.get(Uri.parse('https://tinyurl.com/api-create.php?url=$longUrl')); if (response.statusCode == 200) { return response.body; } else { throw Exception('Failed to shorten URL'); } }

  List<Map<String, dynamic>> _places = []; // Define _places

  Future<void> _getNearbyAmenities() async {
    if (_currentPosition == null){
      print('Current position is not set..');
      return;
    }

    final double latitude = _currentPosition!.latitude;
    final double longitude = _currentPosition!.longitude;

    final String overpassUrl =
    '''https://overpass-api.de/api/interpreter?data=[out:json];
      (node["amenity"="rest_area"](around:4000,$latitude,$longitude);
       node["amenity"="pharmacy"](around:4000,$latitude,$longitude);
       node["tourism"="hotel"](around:4000,$latitude,$longitude);
       node["amenity"="hospital"](around:4000,$latitude,$longitude););
      out;''';

    try {
      final response = await http.get(Uri.parse(overpassUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> results = data['elements'];

        if (results.isNotEmpty) {
          List<Map<String, dynamic>> places = [];

          for (var place in results) {
            String longUrl = 'https://www.google.com/maps/search/?api=1&query=${place['lat']},${place['lon']}';
            String shortUrl = await _shortenUrl(longUrl);

            // Determine the icon type based on the place's 'type'
            String iconType;
            if (place['tags']['amenity'] == 'hotel') {
              iconType = 'hotel';
            } else if (place['tags']['amenity'] == 'pharmacy') {
              iconType = 'pharmacy';
            } else if (place['tags']['amenity'] == 'hospital') {
              iconType = 'hospital';
            } else {
              iconType = 'default';
            }

            places.add({
              'name': place['tags']['name'] ?? 'Unknown place',
              'type': place['tags']['amenity'] ?? place['tags']['tourism'] ?? 'Unknown type',
              'latitude': place['lat'],
              'longitude': place['lon'],
              'url': shortUrl,
              'iconType': iconType,  // Store the icon type for later use
            });
          }

          setState(() {
            _places = places;
          });

          // Log the results in the console for analysis
          for (var place in _places) {
            print('Name: ${place['name']}');
            print('Type: ${place['type']}');
            print('Latitude: ${place['latitude']}');
            print('Longitude: ${place['longitude']}');
            print('URL: ${place['url']}');
            print('Icon Type: ${place['iconType']}');
            print('---');
          }
        } else {
          print('No nearby amenities found.');
        }
      } else {
        print('Failed to load nearby places. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby amenities: $e');
    }
  }

  Color _getBarColor(double value) {
    if (value >= 70) {
      return Colors.green; // High performance
    } else if (value >= 50) {
      return Colors.orange; // Moderate performance
    } else {
      return Colors.red; // Low performance
    }
  }


  @override
  Widget build(BuildContext context) {

    final User? user = FirebaseAuth.instance.currentUser; if (user == null) { return Text("No user is currently logged in."); }
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
              leading: Icon(Icons.add_ic_call_outlined),
              title: Text('Driver condition'),
              onTap: () => Navigator.pushNamed(context, "/driver"),
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
              onTap: () => Navigator.pushNamed(context, "/llogin"),
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
            height: 300, // Height for better spacing
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Added vertical padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20, // Set interval for y-axis
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1, // Set interval for x-axis
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();

                        List<String> labels;

                        if (selectedTimeframe == "Daily") {
                          labels = getXAxisLabels(selectedTimeframe); // Get all labels for daily
                          if (index < labels.length && index % 4 == 0) { // Show labels only for every 4th hour
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Transform.rotate(
                                angle: -pi / 2, // Rotate for better readability
                                child: Text(
                                  labels[index],
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                        } else {
                          // For other timeframes (e.g., Weekly, Monthly), you can return the labels directly
                          labels = getXAxisLabels(selectedTimeframe); // Assuming this method exists for weekly/monthly
                          if (index < labels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                labels[index],
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                        }
                        return Container(); // Return empty container for other indices
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                barGroups: getGraphData(selectedTimeframe).map((spot) {
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: _getBarColor(spot.y),
                        width: 10, // Slimmer bar width
                        borderRadius: BorderRadius.circular(8),
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
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blueAccent, // Background color
              backgroundColor: Colors.white, // Text color
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              elevation: 3, // Shadow effect
            ),
            child: Text(
              "Run Analysis",
              style: TextStyle(
                fontSize: 18, // Font size
                fontWeight: FontWeight.bold, // Bold text
              ),
            ),
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(16), // Increased padding for better spacing
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color
                    borderRadius: BorderRadius.circular(12), // Match the Card's rounded corners
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Recent Activities",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20, // Increased font size for the title
                        ),
                      ),
                      SizedBox(height: 12), // Increased space below the title
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('alertLogs')
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var alertLog = snapshot.data?.docs?.first;
                          if (alertLog == null) {
                            return Center(child: Text("No recent activities found"));
                          }

                          // Convert Timestamp to String
                          Timestamp timestamp = alertLog['timestamp'];
                          String formattedDate = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                          String formattedTime = DateFormat('hh:mm a').format(timestamp.toDate());

                          // Extract relevant part of the location
                          String location = alertLog['location'];
                          String shortLocation = location.split(',')[0];

                          // Format the incident message
                          String driverStatus = alertLog['driverStatus'];
                          String incidentMessage = driverStatus == "sober/awake"
                              ? "No incident"
                              : "$driverStatus driving incident at $shortLocation";

                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.warning, color: Colors.red, size: 30), // Larger icon
                                title: Text(
                                  "Incident Logged",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(incidentMessage, style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 4), // Space between lines
                                    Text("Date: $formattedDate", style: TextStyle(fontSize: 12)),
                                    Text("Time: $formattedTime", style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              Divider(thickness: 1), // Divider between incidents
                            ],
                          );
                        },
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
                  child: _currentPosition == null
                      ? Center(
                    child: CircularProgressIndicator(),
                  )
                      : FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentPosition!, // Initial map center
                      initialZoom: 12.0, // Initial zoom level
                      interactionOptions: const InteractionOptions(
                        flags: ~InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      openStreetMapTileLayer, // Your tile layer for OpenStreetMap

                      MarkerLayer(
                        markers: _places.map((place) {
                          // Determine the icon based on the place's 'iconType'
                          IconData iconData;
                          switch (place['iconType']) {
                            case 'hotel':
                              iconData = Icons.hotel;
                              print("Selected icon: hotel");
                              break;
                            case 'pharmacy':
                              iconData = Icons.local_pharmacy;
                              break;
                            case 'hospital':
                              iconData = Icons.local_hospital;
                              break;
                            default:
                              iconData = Icons.location_on_outlined; // Default icon
                              break;
                          }

                          // Return a Marker widget for each place
                          return Marker(
                            point: LatLng(place['latitude'], place['longitude']),
                            width: 60,
                            height: 60,
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              iconData, // Set the appropriate icon based on place type
                              size: 30,
                              //color: Colors.blue, // You can customize color here
                            ),
                          );
                        }).toList(), // Convert places list to a list of markers
                      ),
                    ],
                  ),
                ),
              ),


              SizedBox(height: 20),
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(16), // Increased padding for better spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recommended Rest Areas",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Increased font size for the title
                ),
              ),
              SizedBox(height: 12), // Increased space below the title
              _places.isEmpty
                  ? Center(
                child: Text(
                  "No recommended Rest Areas found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Prevent scrolling
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  final place = _places[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4), // Space between cards
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12), // Padding inside the ListTile
                      title: Text(
                        place['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${place['type']} - ${place['latitude']}, ${place['longitude']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(place['url']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                // Notify user if URL cannot be launched
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not launch URL')),
                                );
                              }
                            },
                            child: Text(
                              place['url'],
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

            ],
          ),
        ],
      ),
    );
  }
}