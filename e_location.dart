import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';
import 'package:journeyai/pages/login/login_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';  // For JSON decoding
import 'package:http/http.dart' as http;

import 'e_alert.dart';
import 'e_logs.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver Location',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Color customBlue = const Color(0xFF007BFF);
  Color customOrange = const Color(0xFFFFA500);
  int _selectedIndex = 0;

  // Initial location for the map
  LatLng? _currentPosition;
  bool _isLoading = true; // Track if location is being fetched

  String _county = 'County: Not available';
  String _town = 'Town: Not available';
  String _coordinates = 'Coordinates: Not available';

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Get the current position
  }

  // Get current location of the user
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, request the user to enable them
      await Geolocator.openLocationSettings();
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, exit
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, we cannot request them
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );


    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _coordinates = 'Coordinates: ${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E';
      _isLoading = true;
    });
    // Perform reverse geocoding in the background to load it immediately after the coordinates
    _getCityAndStreet(position);

  }

  Future<void> _getCityAndStreet(Position position) async {
    try {
      // Reverse geocoding to get city and street
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (_town == null || _town.isEmpty) {
        _town = "Unknown"; // Fallback value
      }
      // Update city and street later once we get the response
      setState(() {
        _county = 'County: ${placemarks.reversed.last.administrativeArea ?? "Unknown"}'; // locality gives the city
        _town = 'Street: ${placemarks.reversed.last.thoroughfare ?? "Unknown"}'; // street for address
      });
      // Call the method to get nearby amenities using the current location
      _getNearbyAmenities(_currentPosition!.latitude, _currentPosition!.longitude);
    } catch (e) {
      print('Error during reverse geocoding: $e');
    }
  }

  List<Map<String, dynamic>> _places = []; // Define _places

  Future<void> _getNearbyAmenities(double latitude, double longitude) async {
    final String overpassUrl =
    '''https://overpass-api.de/api/interpreter?data=[out:json];
        (node["amenity"="rest_area"](around:3000,$latitude,$longitude);
         node["amenity"="pharmacy"](around:3000,$latitude,$longitude);
         node["tourism"="hotel"](around:3000,$latitude,$longitude);
         node["amenity"="hospital"](around:3000,$latitude,$longitude););
        out;''';

    try {
      final response = await http.get(Uri.parse(overpassUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> results = data['elements'];

        if (results.isNotEmpty) {
          setState(() {
            _places = results.map((place) {
              return {
                'name': place['tags']['name'] ?? 'Unknown place',
                'type': place['tags']['amenity'] ?? place['tags']['tourism'] ?? 'Unknown type',
                'latitude': place['lat'],
                'longitude': place['lon'],
              };
            }).toList();
          });

          // Log the results in the console for analysis
          for (var place in _places) {
            print('Name: ${place['name']}');
            print('Type: ${place['type']}');
            print('Street: ${place['thoroughfare']}');
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBlue,
      body: Column(
        children: [
          // Top bar with image and text
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('lib/pages/ern/assets/navigation.png'), // Car image asset here
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Live Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main container for the map
          Expanded(
            flex: 6, // Reduced the height slightly to fit navbar at the bottom
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
              ),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    // Actual map
                    Container(
                      height: 350,
                      color: Colors.grey[300],
                      child: _currentPosition == null
                          ? Center(child: CircularProgressIndicator()) // Show loading indicator
                          : FlutterMap(
                        options: MapOptions(
                          initialCenter: _currentPosition!,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                              flags: ~InteractiveFlag.doubleTapZoom),
                        ),
                        children: [
                          openStreetMapTileLayer,
                          MarkerLayer(markers: [
                            Marker(
                              point: _currentPosition!, // Current position marker
                              width: 60,
                              height: 60,
                              alignment: Alignment.centerLeft,
                              child: Icon(
                                Icons.location_pin,
                                size: 60,
                                color: Colors.red,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Text under the map
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8), // Add some space between the texts
                          Text(
                            _county,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8), // Add some space between the texts
                          Text(
                            _town,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8), // Add some space between the texts
                          Text(
                            _coordinates,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout), // Sign out icon
            label: 'Sign Out', // Label for accessibility
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Logs',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AlertScreen()),
            );
          } else if (index == 2) {
            signOut();
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LocationScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LogScreen()),
            );
          }
        },
        selectedItemColor: Colors.orange, // Change this to your custom color
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }

  // Function to handle sign out
  void signOut() async {
    await FirebaseAuth.instance.signOut();
    // Redirect to login screen or another appropriate screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
);
