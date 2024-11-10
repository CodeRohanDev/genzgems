// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation

    // Define the scale animation
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);

    _checkLoginStatus();
  }

  // Check if the user is logged in
  void _checkLoginStatus() async {
    // Simulate a delay to show the splash screen for a moment
    await Future.delayed(
        Duration(seconds: 3)); // Changed to 3 seconds for visibility

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is signed in, navigate to HomeScreen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User is not signed in, navigate to LoginScreen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/logo.png',
                height: 150,
                scale: 1,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Gen Z Gems',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito Sans'),
            ),
            Lottie.asset(
              'assets/dotloading.json',
              height: 50,
              width: 1000,
            )
          ],
        ),
      ),
    );
  }
}
