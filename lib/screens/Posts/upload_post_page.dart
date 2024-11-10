// ignore_for_file: prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:genzgems/screens/Profile/profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
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
          lockAspectRatio: false,
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
    if (_croppedImageFile == null) {
      Fluttertoast.showToast(msg: "Please select an image.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "No user is logged in.");
        setState(() {
          _isUploading = false;
        });
        return;
      }

      String userId = user.uid;

      // Read the image as a byte array
      List<int> imageBytes = await _croppedImageFile!.readAsBytes();

      // Decode the image
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

      if (image == null) {
        Fluttertoast.showToast(msg: "Failed to decode image.");
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Compress the image (quality 80 is a good starting point)
      List<int> compressedImageBytes = img.encodeJpg(image, quality: 80);

      // Create a compressed file
      File compressedFile = File(_croppedImageFile!.path)
        ..writeAsBytesSync(compressedImageBytes);

      // Upload compressed image to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('posts/$fileName');
      UploadTask uploadTask = storageRef.putFile(compressedFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Prepare post data
      Map<String, dynamic> postData = {
        'imageUrl': imageUrl,
        'userId': userId,
        'createdAt': Timestamp.now(),
      };

      if (_captionController.text.isNotEmpty) {
        postData['caption'] = _captionController.text;
      }

      List<String> tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      if (tags.isNotEmpty) {
        postData['tags'] = tags;
      }

      DocumentReference postRef =
          await FirebaseFirestore.instance.collection('posts').add(postData);

      // Add tags to Firestore
      for (String tag in tags) {
        DocumentSnapshot tagSnapshot =
            await FirebaseFirestore.instance.collection('tags').doc(tag).get();

        if (tagSnapshot.exists) {
          await FirebaseFirestore.instance.collection('tags').doc(tag).update({
            'posts': FieldValue.arrayUnion([postRef.id])
          });
        } else {
          await FirebaseFirestore.instance.collection('tags').doc(tag).set({
            'posts': [postRef.id],
            'createdAt': Timestamp.now(),
          });
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postRef.id)
          .set({
        'postId': postRef.id,
        'createdAt': Timestamp.now(),
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(7, 165, 210, 247),
      appBar: AppBar(
          title: Text(
        "Upload Post",
        style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1),
      )),
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
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white, // Set color here
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade400),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ], // Add shadow for better look
                        ),
                        child: Center(
                          child: Icon(Icons.camera_alt,
                              size: 60, color: Colors.blue),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius:
                          BorderRadius.circular(16), // Rounded corners
                      child: Image.file(
                        _croppedImageFile!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
              SizedBox(height: 16),
              // Caption field
              Text("Caption",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              SizedBox(
                height: 16,
              ),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: "Write Something about the post...",
                  hintStyle: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text("Tags",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              SizedBox(
                height: 16,
              ),
              // Tags field
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: "Tags (seperated with comma)",
                  hintStyle: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 26),
              // Upload button
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _uploadPost,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 40),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            Text("Upload Post", style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
