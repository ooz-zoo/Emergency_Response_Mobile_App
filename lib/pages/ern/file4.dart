// import 'dart:convert';
//
// import 'package:flutter/material.dart';
//
// class File4 {
//   static void processDataFromFile2(Map<String, dynamic> processedData) {
//     printProcessedData(processedData);
//   }
//
//   static void printProcessedData(Map<String, dynamic> processedData) {
//     // Debugging: Print the received JSON object
//     print("Received Processed Data in File4: ${jsonEncode(processedData)}");
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';

class File4 extends StatefulWidget {
  static final GlobalKey<_File4State> globalKey = GlobalKey<_File4State>();

  File4({Key? key}) : super(key: key); // Constructor with key

  @override
  _File4State createState() => _File4State();

  static void processDataFromFile2(Map<String, dynamic> processedData) {
    print("rece Processed Data: ${jsonEncode(processedData)}");
  }
}

class _File4State extends State<File4> {
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Call static method here after the widget is built
      File4.processDataFromFile2({"key": "value"});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

void main() {
  runApp(MaterialApp(home: File4(key: File4.globalKey)));
}

