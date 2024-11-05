// ignore_for_file: prefer_final_fields

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UploadPostPage extends StatefulWidget {
  @override
  _UploadPostPageState createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  final ImagePicker _picker = ImagePicker();
  File? _croppedImageFile; // Cropped image
  TextEditingController _captionController = TextEditingController();
  TextEditingController _tagsController = TextEditingController();
  bool _isUploading = false;

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {});
      // Navigate to the crop section
      _cropImage(pickedFile.path);
    }
  }

  // Crop image section using image_cropper
  Future<void> _cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          lockAspectRatio: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square, // Enforce square aspect ratio (1:1)
          ],
          hideBottomControls: false, // Allow the user to move the crop window
          showCropGrid: true, // Optional: display grid lines for visual aid
          cropFrameColor: Colors.blue, // Optional: frame color for crop area
          toolbarTitle:
              'Adjust Crop Area', // Optional: Title on Android toolbar
        ),
        IOSUiSettings(
          aspectRatioLockEnabled: true, // Lock aspect ratio on iOS
          minimumAspectRatio: 1.0, // Ensure aspect ratio is 1:1 on iOS
          hidesNavigationBar: true, // Optional: hides navigation bar on iOS
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _croppedImageFile = File(croppedFile.path); // Set cropped image
      });
    }
  }

  // Upload image to Firebase
  Future<void> _uploadPost() async {
    if (_croppedImageFile == null || _captionController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please select an image and add a caption.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Get the current user's ID from FirebaseAuth
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "No user is logged in.");
        setState(() {
          _isUploading = false;
        });
        return;
      }

      String userId = user.uid; // Get the current user's ID

      // Upload cropped image to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('posts/$fileName');
      UploadTask uploadTask = storageRef.putFile(_croppedImageFile!);
      TaskSnapshot taskSnapshot = await uploadTask;

      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Add post to Firestore
      DocumentReference postRef =
          await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': imageUrl,
        'caption': _captionController.text,
        'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
        'userId': userId, // Use current user's ID
        'createdAt': Timestamp.now(),
      });

      // Get the tags from the post
      List<String> tags =
          _tagsController.text.split(',').map((e) => e.trim()).toList();

      // Check and add tags to the tags collection
      for (String tag in tags) {
        DocumentSnapshot tagSnapshot =
            await FirebaseFirestore.instance.collection('tags').doc(tag).get();

        if (tagSnapshot.exists) {
          // Tag exists, add the post ID to the tag's "posts" list
          await FirebaseFirestore.instance.collection('tags').doc(tag).update({
            'posts': FieldValue.arrayUnion([postRef.id])
          });
        } else {
          // Tag does not exist, create a new tag document
          await FirebaseFirestore.instance.collection('tags').doc(tag).set({
            'posts': [postRef.id],
            'createdAt': Timestamp.now(),
          });
        }
      }

      // Add the post to the user's posts collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postRef.id)
          .set({
        'postId': postRef.id,
        'createdAt': Timestamp.now(),
      });

      // Update the posts count in the user's profile
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      Fluttertoast.showToast(msg: "Post uploaded successfully!");
      setState(() {
        _isUploading = false;
        _croppedImageFile = null;
        _captionController.clear();
        _tagsController.clear();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to upload post: $e");
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Build the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Post")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              _croppedImageFile == null
                  ? GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        color: Colors.grey[200],
                        height: 200,
                        child: Center(
                          child: Icon(Icons.camera_alt, size: 50),
                        ),
                      ),
                    )
                  : Image.file(_croppedImageFile!),
              SizedBox(height: 16),
              // Caption field
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: "Add a caption...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              // Tags field
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: "Add tags (comma separated)...",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              // Upload button
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _uploadPost,
                      child: Text("Upload Post"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
