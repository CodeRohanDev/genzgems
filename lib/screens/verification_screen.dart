// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authentication_service.dart'; // Assuming this service is already created

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  int _timeRemaining = 60; // Time in seconds to resend verification
  bool _canResend = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _checkEmailVerificationStatus(); // Initial check
    _startResendTimer();
  }

  // Check email verification status
  Future<void> _checkEmailVerificationStatus() async {
    User? user =
        AuthenticationService().auth.currentUser; // Use the public getter here
    if (user != null) {
      await user.reload(); // Refresh the user info
      if (mounted) {
        setState(() {
          _isEmailVerified = user.emailVerified;
        });

        // If the email is verified, update the Firestore document
        if (_isEmailVerified) {
          // Update the user verification status in Firestore
          await AuthenticationService().updateUserVerificationStatus();

          // Navigate to the home page
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  // Start the timer for resend button
  void _startResendTimer() {
    if (_canResend) return;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_timeRemaining > 0) {
          setState(() {
            _timeRemaining--;
          });
        } else {
          setState(() {
            _canResend = true;
          });
          _timer.cancel();
        }
      }
    });
  }

  // Resend verification email
  Future<void> _resendVerification() async {
    await AuthenticationService().resendVerificationEmail();
    setState(() {
      _canResend = false;
      _timeRemaining = 60;
    });
    _startResendTimer();
  }

  // Check verification status on button press
  Future<void> _onCheckVerificationPressed() async {
    await _checkEmailVerificationStatus();
    if (_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your email is verified!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your email is not verified yet.')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Always cancel the timer when the screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 0, 31, 116),
              const Color.fromARGB(255, 130, 196, 250),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.32,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "Please Check your",
                                  style: TextStyle(
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 25,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  "Inbox",
                                  style: TextStyle(
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 50,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(25),
                        ),
                      ),
                      padding: const EdgeInsets.only(
                        top: 50,
                        bottom: 30,
                        left: 30,
                        right: 30,
                      ),
                      child: Column(
                        children: [
                          if (_isEmailVerified)
                            Text('Your email is verified!',
                                style: TextStyle(fontSize: 18))
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 65,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color.fromARGB(255, 0, 29, 104),
                                          const Color.fromARGB(
                                              255, 0, 123, 224),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      onPressed: _canResend
                                          ? _resendVerification
                                          : null,
                                      child: _canResend
                                          ? Text(
                                              'Resend Verification Email',
                                              style: TextStyle(
                                                fontFamily: 'Nunito Sans',
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                                color: Colors.white,
                                                fontSize: 20,
                                              ),
                                            )
                                          : Text(
                                              'Resend in $_timeRemaining seconds',
                                              style: TextStyle(
                                                fontFamily: 'Nunito Sans',
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                                color: Colors.white,
                                                fontSize: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 35,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 65,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color.fromARGB(255, 0, 29, 104),
                                          const Color.fromARGB(
                                              255, 0, 123, 224),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      onPressed: _onCheckVerificationPressed,
                                      child: Text(
                                        'Check Verification Status',
                                        style: TextStyle(
                                          fontFamily: 'Nunito Sans',
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              top: 50,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // Navigate back to the previous screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
