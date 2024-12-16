import 'package:flutter/material.dart';
import 'package:journeyai/pages/audio/audio_player.dart';
import 'package:journeyai/pages/login/login_page.dart';
import 'package:camera/camera.dart';
import 'dart:developer';
import 'package:journeyai/pages/ern/driver_home.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:journeyai/pages/obj_detect/detect_screen.dart';
import '../../images/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journeyai/pages/login_page.dart';
import 'package:journeyai/pages/obj_detect/scan.dart';

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  late final List<CameraDescription> cameras;
  final TextEditingController searchController = TextEditingController();

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    await setupCameras();
  }

  loadModel(model) async {
    String? res;
    switch (model) {
      case mobilenet:
        res = await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite",
            labels: "assets/mobilenet_v1_1.0_224.txt");
        break;
      default:
        res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt");
    }
    log("$res");
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LornaLoginPage()));
    }
  }

  onSelect(model) {
    loadModel(model);
    final route = MaterialPageRoute(builder: (context) {
      return BradDetectScreen(cameras: cameras, model: model);
    });
    Navigator.of(context).push(route);
  }

  setupCameras() async {
    try {
      cameras = await availableCameras();
    } on CameraException {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFB700),
      appBar: AppBar(
        title: Text("Journey Ai"),
        backgroundColor: Colors.blue,
        // leading: Icon(Icons.menu),
        /*
          actions: [
          IconButton(
            onPressed: () {
              Scaffold.of(context)
                  .openEndDrawer(); // Open the end drawer (right side)
            },
            icon: Icon(Icons.person),
          ),
        ],*/
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                logout();
              },
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFFFFFFFF),
        child: Column(
          children: [
            DrawerHeader(
              child: Icon(Icons.home, size: 48),
            ),
            ListTile(
              leading: Icon(Icons.contact_emergency),
              title: Text("Emergency"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/e_dashboard');
              },
            ),
            ListTile(
              leading: Icon(Icons.card_membership_rounded),
              title: Text("Payments"),
              onTap: () {
                Navigator.pop(context);
                //Bradley Fix this todo
                Navigator.pushNamed(context, '/payment');
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Driver State"),
              onTap: () {
                Navigator.pop(context);
                //Bradley Fix this todo
                Navigator.pushNamed(context, '/driver');
              },
            ),
            ListTile(
              leading: Icon(Icons.music_note),
              title: Text("Audio/Alert Manager"),
              onTap: () {
                Navigator.pop(context);
                //Bradley Fix this todo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          //const ScanPage(model: mobilenet)
                          AudioPlayerWidget()),
                );
              },
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            /*        MyTextField(
            controller: searchController,
            hintText: 'Search',
            obscureText: false,
          ),
       SizedBox(height: 16),

            MyButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScanPage(model: ssd)),
                );
              },
              height: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),*/
            //SizedBox(height: 16),
            SizedBox(
              width: 200,
            ),
            MyButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScanPage(model: mobilenet)),
                );
              },
              height: 90,
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.camera_alt, color: Colors.black),
                  Icon(Icons.arrow_forward, color: Colors.black),
                ],
              ),
            ),
            SizedBox(height: 16),
            MyButton(
              onTap: () {
                Navigator.pushNamed(context, '/driver');
              },
              height: 90,
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.person, color: Colors.black),
                  Icon(Icons.arrow_forward, color: Colors.black),
                ],
              ),
            ),
            SizedBox(height: 100),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Action for first button
                    },
                    child: Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF007BFF),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                                0.5), // Yellow shadow with transparency
                            blurRadius: 15, // Amount of blur for the shadow
                            offset:
                                Offset(0, 5), // Position of the shadow (x, y)
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Action for second button
                    },
                    child: Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF007BFF),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Action for third button
                    },
                    child: Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF007BFF),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF007BFF),
        unselectedItemColor: Color(0xFF007BFF),
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/main_home'); // Navigate to Home
              break;
            case 1:
              Navigator.pushNamed(context, '/logs'); // Navigate to Car
              break;
            case 2:
              Navigator.pushNamed(context, '/payment'); // Navigate to Payments
              break;
            case 3:
              Navigator.pushNamed(
                  context, '/e_dashboard'); // Navigate to Emergency
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership_rounded),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_emergency),
            label: "",
          ),
        ],
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final double height;
  final double width;
  final Widget child;

  const MyButton({
    Key? key,
    required this.onTap,
    required this.height,
    required this.width,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          fillColor: Color(0xFFFFFFFF),
          filled: true,
          hintText: hintText,
        ),
      ),
    );
  }
}
