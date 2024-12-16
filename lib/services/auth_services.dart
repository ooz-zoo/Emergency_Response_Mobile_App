import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register a new user
  Future<UserCredential> registerWithEmailAndPassword(
      String username,
      String fullname,
      String email,
      String phonenumber,
      String address,
      String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      // Create a new user in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          "uid": user.uid,
          "username": username,
          "fullname": fullname,
          "email": email,
          "phonenumber": phonenumber,
          "address": address,
        });
      }

      await user?.sendEmailVerification(); // verify user email address
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign in an existing user
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
  //Error messages

  String errorMessages(String errorCode) {
    String errorMessage;
    switch (errorCode) {
      case "invalid-email":
        errorMessage = "Your email address appears to be malformed.";
        break;
      case "wrong-password":
        errorMessage = "Your password is wrong.";
        break;
      case "user-not-found":
        errorMessage = "User with this email doesn't exist.";
        break;
      case "weak-password":
        errorMessage = "Your password is too weak";
        break;
      case "user-disabled":
        errorMessage = "User with this email has been disabled.";
        break;
      case "email-already-in-use":
        errorMessage = "Email is already in use on different account";
        break;
      case "invalid-credential":
        errorMessage = "Your email is invalid";
        break;
      case "too-many-requests":
        errorMessage = "Too many requests. Try again later.";
        break;
      case "operation-not-allowed":
        errorMessage = "Signing in with Email and Password is not enabled.";
        break;
      case "account-exists-with-different-credential":
        errorMessage = "Account exists with different credentials";
      default:
        errorMessage = 'An unexpected error occurred. Please try again.';
    }
    return errorMessage;
  }

  //GOOGLE SIGN IN
  signInWithGoogle() async {
    //interactive sign in process

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    //user cancels google sign in pop up screen

    if (googleUser == null) return;
    // Obtain the auth details from the request

    final GoogleSignInAuthentication gAuth = await googleUser.authentication;
    // Create a new credential for user

    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    //sign in
    return await _auth.signInWithCredential(credential);
  }

  // Retrieve user details from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  // Retrieve user details
  Future<UserModel?> getUserDetails(String uid) async {
    return await getUser(uid);
  }
}
