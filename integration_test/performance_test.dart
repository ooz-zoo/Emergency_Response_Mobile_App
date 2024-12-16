import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

Future<String> getCurrentLocationWithLogging() async {
  print('Starting to fetch location...');
  DateTime startTime = DateTime.now();

  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services are disabled.');
    return 'Location services are disabled.';
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission denied.');
      return 'Location permission denied.';
    }
  }

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude,
    );

    String street = placemarks[0].street ?? 'Unknown street';
    String city = placemarks[0].locality ?? 'Unknown city';
    String longUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    String mapUrl = await shortenUrl(longUrl);

    String location = '$street, $city\nMap: $mapUrl';
    DateTime endTime = DateTime.now();
    print('Location fetched: $location');
    print('Time taken to fetch location: ${endTime.difference(startTime).inSeconds} seconds');
    return location;
  } catch (e) {
    print('Failed to get location: $e');
    return 'Failed to get location.';
  }
}

Future<String> shortenUrl(String longUrl) async {
  final response = await http.get(Uri.parse('https://tinyurl.com/api-create.php?url=$longUrl'));

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to shorten URL');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized(); // Initialize the binding

  testWidgets('Measure time taken to fetch location', (WidgetTester tester) async {
    // Start the timer
    final stopwatch = Stopwatch()..start();

    // Fetch the location
    String location = await getCurrentLocationWithLogging();

    // Stop the timer
    stopwatch.stop();
    print('Time taken to fetch location: ${stopwatch.elapsedMilliseconds} ms');

    // Assert that the time taken is within acceptable limits
    expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // threshold
  });
}
