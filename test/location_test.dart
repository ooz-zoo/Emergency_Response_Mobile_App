import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

// Custom implementation for testing Geolocator
class TestGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async {
    return true; // Simulate location services being enabled
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.always; // Simulate permission being granted
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return Position(
      latitude: -1.2921,
      longitude: 36.8219,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    ); // Simulate fetching current position
  }
}

// Custom implementation for testing Geocoding
class TestGeocoding extends GeocodingPlatform {
  @override
  Future<List<Placemark>> placemarkFromCoordinates(double latitude, double longitude) async {
    return [
      Placemark(
        street: 'Test Street',
        locality: 'Test City',
      ),
    ]; // Simulate fetching placemark from coordinates
  }
}

// Custom implementation for testing HTTP Client
class TestHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = http.Response('https://tinyurl.com/test', 200);
    return http.StreamedResponse(
      Stream.fromIterable([response.bodyBytes]),
      response.statusCode,
      request: request,
    );
  }
}

// Service class for URL shortening
class UrlShortenerService {
  final http.Client httpClient;

  UrlShortenerService(this.httpClient);

  Future<String> shortenUrl(String longUrl) async {
    final response = await httpClient.get(Uri.parse('https://tinyurl.com/api-create.php?url=$longUrl'));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to shorten URL');
    }
  }
}

void main() {
  late TestGeolocator testGeolocator;
  late TestGeocoding testGeocoding;
  late TestHttpClient testHttpClient;
  late UrlShortenerService urlShortenerService;

  setUp(() {
    testGeolocator = TestGeolocator();
    testGeocoding = TestGeocoding();
    testHttpClient = TestHttpClient();
    urlShortenerService = UrlShortenerService(testHttpClient);
  });

  test('Check if location services are enabled', () async {
    // Act
    final serviceEnabled = await testGeolocator.isLocationServiceEnabled();

    // Assert
    expect(serviceEnabled, true);
  });

  test('Check location permissions', () async {
    // Act
    final permission = await testGeolocator.checkPermission();

    // Assert
    expect(permission, LocationPermission.always);
  });

  test('Fetch current position', () async {
    // Act
    final position = await testGeolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

    // Assert
    expect(position.latitude, -1.2921);
    expect(position.longitude, 36.8219);
  });

  test('Fetch placemark from coordinates', () async {
    // Act
    final placemarks = await testGeocoding.placemarkFromCoordinates(-1.2921, 36.8219);

    // Assert
    expect(placemarks[0].street, 'Test Street');
    expect(placemarks[0].locality, 'Test City');
  });

  test('Shorten URL', () async {
    // Act
    final shortUrl = await urlShortenerService.shortenUrl('https://www.google.com/maps/search/?api=1&query=-1.2921,36.8219');

    // Assert
    expect(shortUrl, 'https://tinyurl.com/test');
  });
}
