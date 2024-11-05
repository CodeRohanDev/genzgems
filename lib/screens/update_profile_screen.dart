// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UpdateProfileScreen extends StatefulWidget {
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final List<String> _categories = []; // List to store fetched categories
  String? _selectedCategory;

  bool _isUsernameAvailable = true;
  bool _isLoading = false;

  // Username validation flags
  bool _isUsernameValidLength = false;
  bool _isUsernameStartsWithLetter = false;
  bool _isUsernameValidCharacters = false;

  User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _fetchCategories();
  }

  void _initializeUserData() {
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _fullNameController.text = doc['fullName'] ?? '';
            _usernameController.text = doc['username'] ?? '';
            _genderController.text = doc['gender'] ?? '';
            _dobController.text = doc['dob'] ?? '';
            _phoneController.text = doc['phone'] ?? '';
            _bioController.text = doc['bio'] ?? '';
            _selectedCategory = doc['category'] ?? ''; // Fetch the category
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            // Handle error
          });
        }
        print('Error fetching user data: $e');
      });
    } else {
      print('No user is logged in');
    }
  }

  // Username validation logic
  void _validateUsername(String value) {
    setState(() {
      _isUsernameValidLength = value.length > 5;
      _isUsernameStartsWithLetter = RegExp(r'^[a-zA-Z]').hasMatch(value);
      _isUsernameValidCharacters = RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value);
    });
  }

  void _fetchCategories() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories.addAll(snapshot.docs.map((doc) => doc['name']));
    });
  }

  Future<void> _checkUsernameAvailability() async {
    setState(() {
      _isUsernameAvailable = false;
    });

    String username = _usernameController.text.trim();

    if (username.isNotEmpty) {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      setState(() {
        _isUsernameAvailable = querySnapshot.docs.isEmpty;
      });
    } else {
      setState(() {
        _isUsernameAvailable = true;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate() && _isUsernameAvailable) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
          'fullName': _fullNameController.text,
          'username': _usernameController.text,
          'gender':
              _genderController.text.isNotEmpty ? _genderController.text : null,
          'dob': _dobController.text.isNotEmpty ? _dobController.text : null,
          'phone':
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
          'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
          'category': _selectedCategory, // Add this line
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profile updated!')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating profile!')));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: Center(child: Text('User is not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Update Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Full Name field
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Username field
              TextField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  suffixIcon: _usernameController.text.isNotEmpty
                      ? Icon(
                          _isUsernameAvailable ? Icons.check : Icons.close,
                          color:
                              _isUsernameAvailable ? Colors.green : Colors.red,
                        )
                      : null,
                ),
                onChanged: (value) {
                  _usernameController.text = value.toLowerCase();
                  _usernameController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _usernameController.text.length),
                  );

                  if (value.isNotEmpty) {
                    _checkUsernameAvailability();
                    _validateUsername(value);
                  }
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: Text("Select Category"),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value; // This should work correctly.
                  });
                },
              ),

              // Show username validation rules when focused
              if (_usernameFocusNode.hasFocus) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Text('Username must be greater than 5 characters.'),
                      ],
                    ),
                    SizedBox(height: 8),
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
                        Text('Username should start with an alphabet.'),
                      ],
                    ),
                    SizedBox(height: 8),
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
                            'Only letters, numbers, ".", and "_" are allowed.'),
                      ],
                    ),
                  ],
                ),
              ],
              SizedBox(height: 16),

              // Gender field
              TextFormField(
                controller: _genderController,
                decoration: InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Date of Birth field
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: "Date of Birth",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dobController.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Phone Number field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Bio field
              // Bio field
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                  counterText: '${_bioController.text.length}/250',
                ),
                maxLines: 3,
                maxLength: 250,
                onChanged: (value) {
                  setState(() {
                    // This will trigger the counterText to update as the user types
                  });
                },
                validator: (value) {
                  if (value != null && value.length > 250) {
                    return 'Bio cannot be more than 250 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Update Profile button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
