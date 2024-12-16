import 'package:flutter/material.dart';
import 'e_input_form.dart';

void main() {
  runApp(const EmptyApp());
} // program entry point

class EmptyApp extends StatelessWidget {
  const EmptyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column( // Main layout
          children: [
            Expanded(
              child: Center(
                child: Column( // Section layout
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200, // Adjusted width
                      height: 200, // Adjusted height
                      child: Image.asset(
                        'lib/pages/ern/assets/add_contact.png',
                        fit: BoxFit.cover, // Ensures the image covers the container
                      ),
                    ),
                    const SizedBox(height: 70), // space between the image and the text
                    const Text(
                      'No Emergency Contacts Found',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FormScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(380, 70),
                    backgroundColor: Colors.orange, // Button background color
                    foregroundColor: Colors.black, // Button text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ), // Remove curved borders
                  ), // Set the width and height/
                  child: const Text(
                    'Register Emergency Contact',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
