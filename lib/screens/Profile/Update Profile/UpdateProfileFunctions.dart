// UpdateProfileFunctions.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

final User? _user = FirebaseAuth.instance.currentUser;

void initializeUserData(
  BuildContext context,
  TextEditingController fullNameController,
  TextEditingController usernameController,
  TextEditingController genderController,
  TextEditingController dobController,
  TextEditingController phoneController,
  TextEditingController bioController,
  ValueSetter<String?> setSelectedCategory, // New parameter
  StateSetter setState,
) {
  if (_user != null) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          fullNameController.text = doc['fullName'] ?? '';
          usernameController.text = doc['username'] ?? '';
          genderController.text = doc['gender'] ?? '';
          dobController.text = doc['dob'] ?? '';
          phoneController.text = doc['phone'] ?? '';
          bioController.text = doc['bio'] ?? '';
          // Use the callback to set _selectedCategory in the screen state
          setSelectedCategory(doc['category']);
        });
      }
    }).catchError((e) {
      print('Error fetching user data: $e');
    });
  } else {
    print('No user is logged in');
  }
}

void fetchCategories(List<String> categories, StateSetter setState) async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('categories').get();
  setState(() {
    categories.addAll(snapshot.docs.map((doc) => doc['name']));
  });
}

// void validateAndCheckUsername(
//   String value,
//   TextEditingController usernameController,
//   StateSetter setState,
//   FocusNode usernameFocusNode,
//   bool isUsernameAvailable,
//   bool isUsernameValidLength,
//   bool isUsernameStartsWithLetter,
//   bool isUsernameValidCharacters,
// ) {
//   setState(() {
//     isUsernameValidLength = value.length > 5;
//     isUsernameStartsWithLetter = RegExp(r'^[a-zA-Z]').hasMatch(value);
//     isUsernameValidCharacters = RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value);
//   });

//   checkUsernameAvailability(usernameController.text.trim(), setState);
// }

// Future<void> checkUsernameAvailability(
//     String username, StateSetter setState) async {
//   if (username.isNotEmpty) {
//     var querySnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .where('username', isEqualTo: username)
//         .get();

//     setState(() {
//       bool isUsernameAvailable = querySnapshot.docs.isEmpty;
//     });
//   }
// }

Future<void> updateProfile(
  BuildContext context,
  GlobalKey<FormState> formKey,
  TextEditingController fullNameController,
  TextEditingController usernameController,
  TextEditingController genderController,
  TextEditingController dobController,
  TextEditingController phoneController,
  TextEditingController bioController,
  String? selectedCategory,
  StateSetter setState,
) async {
  if (formKey.currentState!.validate()) {
    setState(() {
      bool isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({
      'fullName': fullNameController.text,
      'username': usernameController.text,
      'gender': genderController.text,
      'dob': dobController.text,
      'phone': phoneController.text,
      'bio': bioController.text,
      'category': selectedCategory,
    });

    setState(() {
      bool isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
    );

    Navigator.pop(context);
  }
}

Future<void> pickDate(
    BuildContext context, TextEditingController dobController) async {
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  if (selectedDate != null) {
    dobController.text = DateFormat.yMMMd().format(selectedDate);
  }
}

Widget buildValidationRow(bool isValid, String text) {
  return Row(
    children: [
      Icon(
        isValid ? Icons.check : Icons.close,
        color: isValid ? Colors.green : Colors.red,
      ),
      SizedBox(width: 4),
      Text(text),
    ],
  );
}
