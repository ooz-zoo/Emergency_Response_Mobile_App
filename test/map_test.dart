import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
);

void main() {
  final List<Map<String, dynamic>> testPlaces = [
    {'name': 'Rest Area 1', 'type': 'Type 1', 'latitude': 51.5, 'longitude': -0.09},
    {'name': 'Rest Area 2', 'type': 'Type 2', 'latitude': 51.6, 'longitude': -0.10},
  ];

  testWidgets('First Card displays map and marker', (WidgetTester tester) async {
    final LatLng testPosition = LatLng(51.5, -0.09); // Example coordinates

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Card(
                elevation: 4,
                child: Container(
                  width: 300, // Example width
                  height: 250, // Adjust height as needed
                  padding: EdgeInsets.all(8),
                  child: testPosition == null
                      ? Center(
                    child: CircularProgressIndicator(),
                  )
                      : FlutterMap(
                    options: MapOptions(
                      initialCenter: testPosition,
                      initialZoom: 13.0,
                      interactionOptions: const InteractionOptions(
                        flags: ~InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      openStreetMapTileLayer,
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: testPosition,
                            width: 60,
                            height: 60,
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              Icons.location_pin,
                              size: 60,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Container(
                  width: 300, // Example width
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Recommended Rest Areas", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      testPlaces.isEmpty
                          ? Text("No recommended Rest Areas found", style: TextStyle(fontSize: 16))
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: testPlaces.length,
                        itemBuilder: (context, index) {
                          final place = testPlaces[index];
                          return ListTile(
                            title: Text(place['name']),
                            subtitle: Text('${place['type']} - ${place['latitude']}, ${place['longitude']}'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Verify that the CircularProgressIndicator is not displayed
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify that the FlutterMap is displayed
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verify that the Marker is displayed
    expect(find.byIcon(Icons.location_pin), findsOneWidget);

    // Verify that the title is displayed
    expect(find.text("Recommended Rest Areas"), findsOneWidget);

    // Verify that the ListView is displayed
    expect(find.byType(ListView), findsOneWidget);

    // Verify that the ListTiles are displayed
    expect(find.byType(ListTile), findsNWidgets(testPlaces.length));
  });
}
