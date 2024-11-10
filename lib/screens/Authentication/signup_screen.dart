// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'authentication_service.dart'; // Assuming this service is already created
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isUsernameAvailable = true; // Username availability status
  String? _errorMessage;

  // Validation flags for username
  bool _isUsernameValidLength = false;
  bool _isUsernameStartsWithLetter = false;
  bool _isUsernameValidCharacters = false;

  // Validation flags for password
  bool _isPasswordValid = false;
  bool _isPasswordValidLength = false;
  bool _isPasswordNoSpecialChar = true;

  // Validation flag for password match
  bool _isPasswordMatch = true;

  // Focus nodes for username and password fields
  FocusNode _usernameFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  // Function to check if username is available
  Future<void> _checkUsernameAvailability(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    setState(() {
      _isUsernameAvailable =
          querySnapshot.docs.isEmpty; // If no docs, username is available
    });
  }

  // Function to validate username
  void _validateUsername(String username) {
    bool validLength = username.length > 4;
    bool startsWithLetter = RegExp(r'^[a-zA-Z]').hasMatch(username);
    bool validCharacters = RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username);

    setState(() {
      _isUsernameValidLength = validLength;
      _isUsernameStartsWithLetter = startsWithLetter;
      _isUsernameValidCharacters = validCharacters;
    });
  }

  // Function to validate password
  void _validatePassword(String password) {
    bool validLength = password.length >= 6;
    bool noSpecialChar = !password.contains('*');

    setState(() {
      _isPasswordValidLength = validLength;
      _isPasswordNoSpecialChar = noSpecialChar;
      _isPasswordValid = validLength && noSpecialChar;
    });
  }

  // Function to check if passwords match
  void _checkPasswordMatch() {
    setState(() {
      _isPasswordMatch =
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  // Function to handle sign up
  Future<void> _signUp() async {
    String fullName = _fullNameController.text.trim();
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Validate fields
    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (!_isUsernameAvailable) {
      setState(() {
        _errorMessage = 'Username is already taken';
      });
      return;
    }

    // Check if all validations pass
    if (!_isUsernameValidLength ||
        !_isUsernameStartsWithLetter ||
        !_isUsernameValidCharacters) {
      setState(() {
        _errorMessage = 'Username does not meet the required criteria';
      });
      return;
    }

    if (!_isPasswordValid) {
      setState(() {
        _errorMessage =
            'Password must be at least 6 characters long and cannot contain "*"';
      });
      return;
    }

    // Call the sign-up logic from your AuthenticationService
    final result = await AuthenticationService().signUpWithEmailPassword(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
    );

    if (result == null) {
      setState(() {
        _errorMessage = 'Sign up failed. Please try again.';
      });
    } else {
      Navigator.pushReplacementNamed(context,
          '/email_verification'); // Navigate to email verification page
    }
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(() {
      setState(() {}); // Force update when focus changes
    });
    _passwordFocusNode.addListener(() {
      setState(() {}); // Force update when password field is clicked
    });
  }

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
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
        child: CustomScrollView(
          slivers: [
            // Show error message if exists
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Back Button
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0, left: 16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // Navigate back to the previous screen
                        },
                      ),
                    ),
                  ),
                  // Main content
                  Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Join Now",
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

            // Full Name Field
            SliverToBoxAdapter(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 50, bottom: 30, left: 30, right: 30),
                  child: Column(
                    children: [
                      TextField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.grey, // Color of the label
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Enable floating label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color:
                                    Colors.grey), // Customize color if needed
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                15), // Keep radius consistent
                            borderSide: BorderSide(
                                color: Colors
                                    .blue), // Customize color when focused
                          ),
                          prefixIcon: Icon(Icons.person),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20), // Increase vertical padding
                        ),
                      ),
                      SizedBox(height: 16),

                      // Username Field (with real-time check)
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        decoration: InputDecoration(
                          suffixIcon: _usernameController.text.isNotEmpty
                              ? Icon(
                                  _isUsernameAvailable
                                      ? Icons.check
                                      : Icons.close,
                                  color: _isUsernameAvailable
                                      ? Colors.green
                                      : Colors.red,
                                )
                              : null,
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.grey, // Color of the label
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Enable floating label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color:
                                    Colors.grey), // Customize color if needed
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                15), // Keep radius consistent
                            borderSide: BorderSide(
                                color: Colors
                                    .blue), // Customize color when focused
                          ),
                          prefixIcon: Icon(Icons.person),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20), // Increase vertical padding
                        ),
                        onChanged: (value) {
                          // Auto-convert to lowercase
                          _usernameController.text = value.toLowerCase();
                          _usernameController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: _usernameController.text.length));

                          if (value.isNotEmpty) {
                            _checkUsernameAvailability(value);
                            _validateUsername(value);
                          }
                        },
                      ),
                      SizedBox(height: 16),

                      // Show validation list only if the username field is focused
                      if (_usernameFocusNode.hasFocus) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Length check
                            Row(
                              children: [
                                Icon(
                                  _isUsernameValidLength
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isUsernameValidLength
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                    'Username must be greater than 5 characters.')
                              ],
                            ),
                            SizedBox(height: 8),

                            // Starts with letter check
                            Row(
                              children: [
                                Icon(
                                  _isUsernameStartsWithLetter
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isUsernameStartsWithLetter
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Username should start with an alphabet.')
                              ],
                            ),
                            SizedBox(height: 8),

                            // Valid characters check
                            Row(
                              children: [
                                Icon(
                                  _isUsernameValidCharacters
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isUsernameValidCharacters
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                    'Only letters, numbers, ".", and "_" are allowed.')
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ],

                      // Email Field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.grey, // Color of the label
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Enable floating label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color:
                                    Colors.grey), // Customize color if needed
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                15), // Keep radius consistent
                            borderSide: BorderSide(
                                color: Colors
                                    .blue), // Customize color when focused
                          ),
                          prefixIcon: Icon(Icons.email),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20), // Increase vertical padding
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),

                      // Password Field with real-time validation
                      TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        focusNode: _passwordFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.grey, // Color of the label
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Enable floating label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color:
                                    Colors.grey), // Customize color if needed
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                15), // Keep radius consistent
                            borderSide: BorderSide(
                                color: Colors
                                    .blue), // Customize color when focused
                          ),
                          prefixIcon: Icon(Icons.password), //
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20), // Increase vertical padding
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                        onChanged: (value) {
                          _validatePassword(value);
                        },
                      ),
                      SizedBox(height: 16),

                      // Show Password Validation Messages
                      if (_passwordFocusNode.hasFocus) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isPasswordValidLength
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isPasswordValidLength
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Password must be at least 6 characters.')
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  _isPasswordNoSpecialChar
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isPasswordNoSpecialChar
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Password cannot contain "*"')
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ],

                      // Confirm Password Field with real-time password match check
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.grey, // Color of the label
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Enable floating label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color:
                                    Colors.grey), // Customize color if needed
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                15), // Keep radius consistent
                            borderSide: BorderSide(
                                color: Colors
                                    .blue), // Customize color when focused
                          ),
                          prefixIcon: Icon(Icons.password),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20), // Increase vertical padding
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        onChanged: (value) {
                          _checkPasswordMatch();
                        },
                      ),
                      SizedBox(height: 16),

                      // Show error message if passwords don't match
                      if (!_isPasswordMatch)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Passwords do not match',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      // Sign Up Button (Always enabled)
                      SizedBox(
                        width: double.infinity,
                        height: 65, // Increased height
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                15), // Match TextField radius
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 0, 29,
                                    104), // End color of the gradient
                                const Color.fromARGB(255, 0, 123,
                                    224), // Start color of the gradient
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    15), // Match TextField radius
                              ),
                              backgroundColor: Colors
                                  .transparent, // Make background transparent
                              shadowColor: Colors
                                  .transparent, // Remove shadow to show gradient
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Sign Up',
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
            ),
          ],
        ),
      ),
    );
  }
}
