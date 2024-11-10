// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:genzgems/screens/Authentication/authentication_service.dart';
import 'package:genzgems/screens/Authentication/forgot_password_screen.dart';
import 'package:genzgems/screens/Home/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false; // To toggle password visibility
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  // Call the login function from the service
  Future<void> _login() async {
    String usernameOrEmail = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Check for empty fields
    if (usernameOrEmail.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
      errorMessage = null; // Clear previous error message
    });

    // Start animation
    _animationController.forward();

    // Call the AuthenticationService to login with either email or username
    final result = await AuthenticationService()
        .signInWithEmailPasswordOrUsername(usernameOrEmail, password);

    // Stop animation and loading
    _animationController.reverse();
    setState(() {
      _isLoading = false; // Stop loading
    });

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen()), // Go to home page on success
      );
    } else {
      setState(() {
        errorMessage = 'Invalid credentials. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(
                  255, 0, 31, 116), // End color of the gradient
              const Color.fromARGB(
                  255, 130, 196, 250), // Start color of the gradient
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
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
                              "Welcome Back",
                              style: TextStyle(
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 25,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "Gen Z Gems",
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
                        top: 20, bottom: 30, left: 30, right: 30),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: errorMessage != null
                              ? Text(
                                  errorMessage!,
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 0.5),
                                )
                              : SizedBox.shrink(),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        // Email TextField
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email or Username',
                            labelStyle: TextStyle(
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.grey,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
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
                            contentPadding: EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Password TextField
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.grey,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
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
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Login Button
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: SizedBox(
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
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : _login, // Disable if loading
                                child:
                                    _isLoading // Show loading indicator if logging in
                                        ? CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          )
                                        : Text(
                                            'Login',
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
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/forgot_password');
                              },
                              child: Text(
                                "Forgot your Password?",
                                style: TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Divider(),
                        SizedBox(height: 10),
                        // Sign Up Redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't Have an Account? ",
                              style: TextStyle(
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
