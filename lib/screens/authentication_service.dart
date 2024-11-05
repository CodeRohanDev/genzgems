import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Public getter for _auth
  FirebaseAuth get auth => _auth;

  // Sign up with email and password
  Future<User?> signUpWithEmailPassword({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Save user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'username': username,
        'email': email,
        'isVerified': false, // Initially set verification status to false
      });

      return userCredential.user;
    } catch (e) {
      print('Sign up failed: $e');
      return null;
    }
  }

  // Resend email verification
  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Update verification status in Firestore after email verification
  Future<void> updateUserVerificationStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'isVerified': true, // Set isVerified to true
        });
      } catch (e) {
        print("Error updating user verification status: $e");
      }
    }
  }

  // Sign in with email and password or username
  Future<User?> signInWithEmailPasswordOrUsername(
      String usernameOrEmail, String password) async {
    try {
      // Check if the input is an email
      bool isEmail = usernameOrEmail.contains('@');

      if (isEmail) {
        // Login with email
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: usernameOrEmail,
          password: password,
        );
        return userCredential.user;
      } else {
        // Login with username
        // First, find the email associated with the username
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail)
            .get();

        if (snapshot.docs.isEmpty) {
          return null; // No user found with this username
        }

        // Assuming the username is unique, get the email associated with the username
        String email = snapshot.docs.first['email'];

        // Now, sign in with the email found
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return userCredential.user;
      }
    } catch (e) {
      print('Login failed: $e');
      return null;
    }
  }
}
