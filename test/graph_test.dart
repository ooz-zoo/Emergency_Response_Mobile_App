import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

void main() {
  testWidgets('BarChart and ElevatedButton test', (WidgetTester tester) async {
    final List<BarChartGroupData> barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: 10,
            color: Colors.blue,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: 20,
            color: Colors.blue,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
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
                            List<String> labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                            if (index % 4 == 0 && index < labels.length) {
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
                    minY: 0,
                    maxY: 100,
                    barGroups: barGroups,
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Simulate button press
                },
                child: Text("Start Simulation"),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    // Verify that the BarChart is displayed
    expect(find.byType(BarChart), findsOneWidget);

    // Verify that the ElevatedButton is displayed
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Verify that the ElevatedButton has the correct text
    expect(find.text("Start Simulation"), findsOneWidget);
  });
}
