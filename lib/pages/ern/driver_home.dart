import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../ern/simulation_helper.dart';


List<CameraDescription>? cameras;

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _timer = Timer.periodic(Duration(seconds: 7), (Timer t) {
      runModel();
    });
  }

  void initializeCamera() async {
    cameras = await availableCameras();
    loadCamera();
    loadModel();
  }

  loadCamera() {
    cameraController = CameraController(cameras![1], ResolutionPreset.medium);
    cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        cameraController!.startImageStream((CameraImage image) {
          cameraImage = image;
        });
      });
    });
  }

  bool isNavigated = false;
  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      predictions?.forEach((element) {
        setState(() {
          output = element['label'];
          if (!isNavigated) {
            isNavigated = true;
            DateTime detectedTime = DateTime.now();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardScreen(
                      detectedCondition: output,
                        detectedTime: detectedTime,
                    ),
              ),
            );
            //saveCondition(output);
          }
        });
      });
    }
  }



  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Facial Recognition App')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          Text(
            output,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          )
        ],
      ),
    );
  }
}

//SimulationServiceHelper.processDriverCondition(output); // Pass the condition directly

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tflite/flutter_tflite.dart';
// import 'dart:async'; // Import this for Timer
// import 'package:journeyai/pages/main_home.dart';
//
// List<CameraDescription>? cameras;
//
// class DriverHome extends StatefulWidget {
//   const DriverHome({super.key});
//   @override
//   State<DriverHome> createState() => _DriverHomeState();
// }
//
// class _DriverHomeState extends State<DriverHome> {
//   CameraImage? cameraImage;
//   CameraController? cameraController;
//   String output = '';
//   Timer? _timer; // Timer variable to hold the periodic timer
//
//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//     // Set up a periodic timer to run every 7 seconds
//     _timer = Timer.periodic(Duration(seconds: 7), (Timer t) {
//       runModel();
//     });
//   }
//
//   void initializeCamera() async {
//     cameras = await availableCameras(); // Fetch available cameras
//     loadCamera();
//     loadModel();
//   }
//
//   loadCamera() {
//     cameraController = CameraController(cameras![1], ResolutionPreset.medium);
//     cameraController!.initialize().then((_) {
//       if (!mounted) return;
//       setState(() {
//         cameraController!.startImageStream((CameraImage image) {
//           cameraImage = image;
//         });
//       });
//     });
//   }
//
//   runModel() async {
//     if (cameraImage != null) {
//       var predictions = await Tflite.runModelOnFrame(
//         bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
//         imageHeight: cameraImage!.height,
//         imageWidth: cameraImage!.width,
//         imageMean: 127.5,
//         imageStd: 127.5,
//         rotation: 90,
//         numResults: 2,
//         threshold: 0.1,
//         asynch: true,
//       );
//       predictions?.forEach((element) {
//         setState(() {
//           output = element['label'];
//         });
//       });
//     }
//   }
//
//   loadModel() async {
//     await Tflite.loadModel(
//       model: "assets/model.tflite",
//       labels: "assets/labels.txt",
//     );
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel(); // Cancel the timer when the widget is disposed
//     cameraController?.dispose(); // Dispose of the camera controller
//     Tflite.close(); // Close the Tflite session
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Facial Recognition App')),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(20),
//             child: Container(
//               height: MediaQuery.of(context).size.height * 0.7,
//               width: MediaQuery.of(context).size.width,
//               child: !cameraController!.value.isInitialized
//                   ? Container()
//                   : AspectRatio(
//                 aspectRatio: cameraController!.value.aspectRatio,
//                 child: CameraPreview(cameraController!),
//               ),
//             ),
//           ),
//           Text(
//             output,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//           )
//         ],
//       ),
//     );
//   }
// }



// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tflite/flutter_tflite.dart';
// import 'dart:async'; // Import this for Timer
// import 'package:journeyai/pages/main_home.dart';
//
// List<CameraDescription>? cameras;
//
// class DriverHome extends StatefulWidget {
//   const DriverHome({super.key});
//
//   @override
//   State<DriverHome> createState() => _DriverHomeState();
// }
//
// class _DriverHomeState extends State<DriverHome> {
//   CameraImage? cameraImage;
//   CameraController? cameraController;
//   String output = '';
//   Timer? _timer; // Timer variable to hold the periodic timer
//
//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//
//     // Set up a periodic timer to run every 7 seconds
//     _timer = Timer.periodic(Duration(seconds: 7), (Timer t) {
//       runModel();
//     });
//   }
//
//   void initializeCamera() async {
//     cameras = await availableCameras(); // Fetch available cameras
//     loadCamera();
//     loadModel();
//   }
//
//   loadCamera() {
//     cameraController = CameraController(cameras![1], ResolutionPreset.medium);
//     cameraController!.initialize().then((_) {
//       if (!mounted) return;
//
//       setState(() {
//         cameraController!.startImageStream((CameraImage image) {
//           cameraImage = image;
//         });
//       });
//     });
//   }
//
//   runModel() async {
//     if (cameraImage != null) {
//       var predictions = await Tflite.runModelOnFrame(
//           bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
//           imageHeight: cameraImage!.height,
//           imageWidth: cameraImage!.width,
//           imageMean: 127.5,
//           imageStd: 127.5,
//           rotation: 90,
//           numResults: 2,
//           threshold: 0.1,
//           asynch: true);
//
//       predictions?.forEach((element) {
//         setState(() {
//           output = element['label'];
//         });
//       });
//     }
//   }
//
//   loadModel() async {
//     await Tflite.loadModel(
//         model: "assets/model.tflite", labels: "assets/labels.txt");
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel(); // Cancel the timer when the widget is disposed
//     cameraController?.dispose(); // Dispose of the camera controller
//     Tflite.close(); // Close the Tflite session
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Facial Recognition App')),
//       body: Column(children: [
//         Padding(
//           padding: EdgeInsets.all(20),
//           child: Container(
//             height: MediaQuery.of(context).size.height * 0.7,
//             width: MediaQuery.of(context).size.width,
//             child: !cameraController!.value.isInitialized
//                 ? Container()
//                 : AspectRatio(
//                     aspectRatio: cameraController!.value.aspectRatio,
//                     child: CameraPreview(cameraController!),
//                   ),
//           ),
//         ),
//         Text(
//           output,
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//         )
//       ]),
//     );
//   }
// }
//
// /*
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tflite/flutter_tflite.dart';
// import 'dart:async'; // Import this for Timer
// import 'package:journeyai/pages/main_home.dart';
//
// List<CameraDescription>? cameras;
//
// class DriverHome extends StatefulWidget {
//   const DriverHome({super.key});
//
//   @override
//   State<DriverHome> createState() => _DriverHomeState();
// }
//
// class _DriverHomeState extends State<DriverHome> {
//   CameraImage? cameraImage;
//   CameraController? cameraController;
//   String output = '';
//   Timer? _timer; // Timer variable to hold the periodic timer
//
//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//
//     // Set up a periodic timer to run every 7 seconds
//     _timer = Timer.periodic(Duration(seconds: 7), (Timer t) {
//       runModel();
//     });
//   }
//
//   void initializeCamera() async {
//     cameras = await availableCameras(); // Fetch available cameras
//     loadCamera();
//     loadModel();
//   }
//
//   loadCamera() {
//     cameraController = CameraController(cameras![1], ResolutionPreset.medium);
//     cameraController!.initialize().then((_) {
//       if (!mounted) return;
//
//       setState(() {
//         cameraController!.startImageStream((CameraImage image) {
//           cameraImage = image;
//         });
//       });
//     });
//   }
//
//   runModel() async {
//     if (cameraImage != null) {
//       var predictions = await Tflite.runModelOnFrame(
//           bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
//           imageHeight: cameraImage!.height,
//           imageWidth: cameraImage!.width,
//           imageMean: 127.5,
//           imageStd: 127.5,
//           rotation: 90,
//           numResults: 2,
//           threshold: 0.1,
//           asynch: true);
//
//       predictions?.forEach((element) {
//         setState(() {
//           output = element['label'];
//         });
//       });
//     }
//   }
//
//   loadModel() async {
//     await Tflite.loadModel(
//         model: "assets/model.tflite", labels: "assets/labels.txt");
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel(); // Cancel the timer when the widget is disposed
//     cameraController?.dispose(); // Dispose of the camera controller
//     Tflite.close(); // Close the Tflite session
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Facial Recognition App')),
//       body: Column(children: [
//         Padding(
//           padding: EdgeInsets.all(20),
//           child: Container(
//             height: MediaQuery.of(context).size.height * 0.7,
//             width: MediaQuery.of(context).size.width,
//             child: !cameraController!.value.isInitialized
//                 ? Container()
//                 : AspectRatio(
//               aspectRatio: cameraController!.value.aspectRatio,
//               child: CameraPreview(cameraController!),
//             ),
//           ),
//         ),
//         Text(
//           output,
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//         )
//       ]),
//     );
//   }
// }
// */
