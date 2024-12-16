import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';

List<Map<String, dynamic>> _places = [];

Future<void> _getNearbyAmenities(http.Client client, Function setState, LatLng? _currentPosition) async {
  if (_currentPosition == null) {
    print('Current position is not set..');
    return;
  }

  final double latitude = _currentPosition.latitude;
  final double longitude = _currentPosition.longitude;

  final String overpassUrl =
  '''https://overpass-api.de/api/interpreter?data=[out:json];
        (node["amenity"="rest_area"](around:2000,$latitude,$longitude);
         node["amenity"="pharmacy"](around:2000,$latitude,$longitude);
         node["tourism"="hotel"](around:2000,$latitude,$longitude);
         node["amenity"="hospital"](around:2000,$latitude,$longitude););
        out;''';

  try {
    final response = await client.get(Uri.parse(overpassUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<dynamic> results = data['elements'];

      if (results.isNotEmpty) {
        List<Map<String, dynamic>> places = [];

        for (var place in results) {
          String longUrl = 'https://www.google.com/maps/search/?api=1&query=${place['lat']},${place['lon']}';
          String shortUrl = await _shortenUrl(longUrl);

          places.add({
            'name': place['tags']['name'] ?? 'Unknown place',
            'type': place['tags']['amenity'] ?? place['tags']['tourism'] ?? 'Unknown type',
            'latitude': place['lat'],
            'longitude': place['lon'],
            'url': shortUrl,
          });
        }
        setState(() {
          _places = places;
        });

        // Log the results in the console for analysis
        for (var place in _places) {
          print('Name: ${place['name']}');
          print('Type: ${place['type']}');
          print('Street: ${place['thoroughfare']}');
          print('URL: ${place['url']}');
          print('---');
        }
      } else {
        setState(() {
          _places = [];
        });
        print('No nearby amenities found.');
      }
    } else {
      setState(() {
        _places = [];
      });
      print('Failed to load nearby places. Status code: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      _places = [];
    });
    print('Error fetching nearby amenities: $e');
  }
}

Future<String> _shortenUrl(String longUrl) async {
  // Mock URL shortening function
  return longUrl;
}

void main() {
  test('Fetches nearby amenities successfully', () async {
    final mockClient = MockClient((request) async {
      final response = {
        'elements': [
          {
            'tags': {'name': 'Test Place', 'amenity': 'rest_area'},
            'lat': 51.5,
            'lon': -0.09,
          },
        ],
      };
      return http.Response(json.encode(response), 200);
    });

    final mockSetState = (Function fn) => fn();
    final mockPosition = LatLng(51.5, -0.09);

    await _getNearbyAmenities(mockClient, mockSetState, mockPosition);

    // Verify that the places list is populated
    expect(_places.isNotEmpty, true);
    expect(_places.first['name'], 'Test Place');
    expect(_places.first['type'], 'rest_area');
  });

  test('Handles no nearby amenities found', () async {
    final mockClient = MockClient((request) async {
      final response = {'elements': []};
      return http.Response(json.encode(response), 200);
    });

    final mockSetState = (Function fn) => fn();
    final mockPosition = LatLng(51.5, -0.09);

    await _getNearbyAmenities(mockClient, mockSetState, mockPosition);

    // Verify that the places list is empty
    expect(_places.isEmpty, true);
  });

  test('Handles HTTP error', () async {
    final mockClient = MockClient((request) async {
      return http.Response('Error', 500);
    });

    final mockSetState = (Function fn) => fn();
    final mockPosition = LatLng(51.5, -0.09);

    await _getNearbyAmenities(mockClient, mockSetState, mockPosition);

    // Verify that the places list is empty
    expect(_places.isEmpty, true);
  });
}
