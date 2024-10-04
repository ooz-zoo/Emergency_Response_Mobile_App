import 'package:flutter/material.dart';
import 'package:journeyai/pages/login/login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage()
        /* home: Scaffold(
        backgroundColor: Color(0xFF2D3436),
        appBar: AppBar(
          title: Text("Journey AI"),
          backgroundColor: Color(0xFFD63031),
          elevation: 2,
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.logout))],
        ),
        body: Center(
            child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(),
              ),
            );
          },
          child: Center(
            child: Container(
              height: 60,
              width: 350,
              color: Color(0xFFD63031),
              child: Text("Login"),
            ),
          ),
        )),
      ),*/
        );
  }
}
