import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:journeyai/models/user.dart';
import 'package:journeyai/pages/login_page.dart';
//import 'package:intelligent_payment_system/rough%20pages/edit_profile.dart';
import 'package:journeyai/services/auth_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  UserModel? _user; //hold user data

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Replace with the UID of the logged-in user
    String uid = currentUser!.uid;

    UserModel? user = await _authService.getUserDetails(uid);
    if (user != null) {
      setState(() {
        _user = user; // Update _user with fetched data
      });
    } else {
      print("User data could not be retrieved.");
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LornaLoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue[50],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    //Image.asset('/images/profile_icon.png'),
                    backgroundColor: Colors.blue[900],
                  ),
                  SizedBox(height: 10),
                  if (_user != null) ...[
                    Text(
                      _user!.username,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    Text(
                      "John Doe",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ]
                  // Text('Last visit: 04/08/2019'),
                ],
              ),
            ),
            SizedBox(height: 30),
            if (_user != null) ...[
              _buildProfileDetail('Name', _user!.fullname),
              _buildProfileDetail('Your Email', _user!.email),
              _buildProfileDetail('Your Phone', _user!.phonenumber),
              _buildProfileDetail('Address', _user!.address),
            ] else ...[
              _buildProfileDetail('Name', "John Doe"),
              _buildProfileDetail('Your Email', "jd@gmail.com"),
              _buildProfileDetail('Your Phone', "+254712345678"),
              _buildProfileDetail('Address', "Kenya"),
            ],
            Center(
              child: ElevatedButton(
                onPressed: () {
                  /*
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => 
                  EditProfilePage()
                  ),
                ); */
                },
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[900],
                    minimumSize: Size(screenWidth - 70, 50)),
                child: const Text("Edit Profile"),
              ),
            ),
            Container(
                margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                child: Column(children: [
                  GestureDetector(
                    onTap: () async {
                      logout();
                    },
                    child: Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.blue[900], fontWeight: FontWeight.w600),
                    ),
                  )
                ]))
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Divider(),
        ],
      ),
    );
  }
}
