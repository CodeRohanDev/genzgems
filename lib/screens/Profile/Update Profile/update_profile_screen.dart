import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'UpdateProfileFunctions.dart';

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

  final List<String> _categories = [];
  String? _selectedCategory;

  bool _isUsernameAvailable = true;
  bool _isLoading = false;

  bool _isUsernameValidLength = false;
  bool _isUsernameStartsWithLetter = false;
  bool _isUsernameValidCharacters = false;

  @override
  void initState() {
    super.initState();
    initializeUserData(
      context,
      _fullNameController,
      _usernameController,
      _genderController,
      _dobController,
      _phoneController,
      _bioController,
      (category) {
        setState(() {
          _selectedCategory = category;
        });
      }, // Callback for setting _selectedCategory
      setState,
    );
    fetchCategories(_categories, setState);
  }

  // Function to calculate profile completion percentage
  double calculateProfileCompletion() {
    int completedFields = 0;

    if (_fullNameController.text.isNotEmpty) completedFields++;
    if (_usernameController.text.isNotEmpty) completedFields++;
    if (_genderController.text.isNotEmpty) completedFields++;
    if (_dobController.text.isNotEmpty) completedFields++;
    if (_phoneController.text.isNotEmpty) completedFields++;
    if (_bioController.text.isNotEmpty) completedFields++;
    if (_selectedCategory != null) completedFields++;

    return (completedFields / 7) * 100; // Total 7 fields to check
  }

  void validateAndCheckUsername(
    String value,
    TextEditingController usernameController,
    StateSetter setState,
    FocusNode usernameFocusNode,
  ) {
    bool isUsernameValidLength = value.length > 4;
    bool isUsernameStartsWithLetter = RegExp(r'^[a-zA-Z]').hasMatch(value);
    bool isUsernameValidCharacters =
        RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value);

    setState(() {
      // Update these boolean flags based on the current input
      _isUsernameValidLength = isUsernameValidLength;
      _isUsernameStartsWithLetter = isUsernameStartsWithLetter;
      _isUsernameValidCharacters = isUsernameValidCharacters;
    });

    if (isUsernameValidLength &&
        isUsernameStartsWithLetter &&
        isUsernameValidCharacters) {
      checkUsernameAvailability(usernameController.text.trim(), setState);
    }
  }

  Future<void> checkUsernameAvailability(
      String username, StateSetter setState) async {
    if (username.isNotEmpty) {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      setState(() {
        _isUsernameAvailable = querySnapshot.docs.isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
          title: Text(
        "Edit Profile",
        style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1),
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile completion box with progress bar
              Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Completion',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: calculateProfileCompletion() / 100,
                      color: Colors.blue,
                      backgroundColor: Colors.blue.shade100,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${calculateProfileCompletion().toStringAsFixed(0)}% complete',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Full Name field
              Container(
                height: 670,
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Full Name",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      SizedBox(
                        height: 12,
                      ),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          hintStyle: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16),
                      Text("Username",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      SizedBox(
                        height: 12,
                      ),
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        decoration: InputDecoration(
                          hintText: "Username",
                          hintStyle: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        ),
                        onChanged: (value) {
                          validateAndCheckUsername(value, _usernameController,
                              setState, _usernameFocusNode);
                        },
                      ),
                      if (_usernameFocusNode.hasFocus) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildValidationRow(_isUsernameValidLength,
                                'Username must be greater than 5 characters.'),
                            buildValidationRow(_isUsernameStartsWithLetter,
                                'Username should start with an alphabet.'),
                            buildValidationRow(_isUsernameValidCharacters,
                                'Only letters, numbers, ".", and "_" are allowed.'),
                          ],
                        ),
                      ],
                      SizedBox(height: 16),
                      Text(
                        "Bio",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          hintText: "Bio",
                          hintStyle: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '${_bioController.text.length}/250',
                        ),
                        maxLines: 3,
                        maxLength: 250,
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (value) {
                          if (value != null && value.length > 250) {
                            return 'Bio cannot be more than 250 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Text("Category",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      SizedBox(
                        height: 12,
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                            border: Border.all(width: 0.5),
                            borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonFormField<String>(
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
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Gender",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      TextFormField(
                        controller: _genderController,
                        decoration: InputDecoration(
                          hintText: "Gender",
                          hintStyle: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Date Of Birth",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      TextFormField(
                        controller: _dobController,
                        decoration: InputDecoration(
                          hintText: "DOB",
                          hintStyle: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.datetime,
                        onTap: () => pickDate(context, _dobController),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16),
                      Text("Phone",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      SizedBox(
                        height: 12,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: "+91 12345 67890",
                          hintStyle: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => updateProfile(
                          context,
                          _formKey,
                          _fullNameController,
                          _usernameController,
                          _genderController,
                          _dobController,
                          _phoneController,
                          _bioController,
                          _selectedCategory,
                          setState,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                  shadowColor: Colors.blue.shade400,
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
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
