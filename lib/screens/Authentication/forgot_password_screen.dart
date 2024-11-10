// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:genzgems/screens/Authentication/authentication_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? successMessage;
  String? errorMessage;

  Future<void> _sendResetLink() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email.';
      });
      return;
    }

    try {
      await AuthenticationService().sendPasswordResetEmail(email);
      setState(() {
        successMessage = 'Reset link sent! Check your email.';
        errorMessage = null; // Clear any previous error message
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error sending reset link. Please try again.';
        successMessage = null; // Clear any previous success message
      });
    }
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
              padding: const EdgeInsets.only(bottom: 0),
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
                                  "Trouble with Password",
                                  style: TextStyle(
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 25,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  "Reset now",
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
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 50,
                          bottom: 30,
                          left: 30,
                          right: 30,
                        ),
                        child: Column(
                          children: [
                            if (successMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  successMessage!,
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: Colors.grey,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                prefixIcon: Icon(Icons.email),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 20),
                              ),
                            ),
                            SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              height: 65,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(255, 0, 29, 104),
                                      const Color.fromARGB(255, 0, 123, 224),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _sendResetLink,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    'Send Reset Link',
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
                          ],
                        ),
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
