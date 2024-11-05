// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:genzgems/screens/followers_following_screen.dart';
import 'package:genzgems/screens/post_details_screen.dart';
import 'dart:io';

// Build profile header with profile picture, full name, username, and bio
Widget buildProfileHeader(
  String? profileImageUrl,
  String fullName,
  String username,
  String bio,
  String? category, // New parameter for category
  BuildContext context,
) {
  final ImagePicker _picker = ImagePicker();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => showProfileDialog(profileImageUrl, context, _picker),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/logo.png') as ImageProvider,
              child: profileImageUrl == null
                  ? Icon(Icons.person, color: Colors.white, size: 70)
                  : null,
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1),
              Text(
                '@$username',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
      SizedBox(height: 15),

      SizedBox(height: 5),
      // Display category if available
      if (category != null && category.isNotEmpty)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[300],
          ),
          child: Text(
            category,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      SizedBox(height: 5),
      Text(
        bio,
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        maxLines: null,
        softWrap: true,
      ),
    ],
  );
}

// Show profile image options dialog
Future<void> showProfileDialog(
    String? profileImageUrl, BuildContext context, ImagePicker picker) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Profile Photo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Display "View" option only if a profile image URL is available
              if (profileImageUrl != null)
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                        showProfileImage(profileImageUrl, context);
                      },
                    ),
                    Text("View", style: TextStyle(color: Colors.blue)),
                  ],
                ),

              // "Edit" option is always available
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.green),
                    onPressed: () async {
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        await uploadImageToFirebase(image, context);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Text("Edit", style: TextStyle(color: Colors.green)),
                ],
              ),

              // Display "Remove" option only if a profile image URL is available
              if (profileImageUrl != null)
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        removeProfileImage(profileImageUrl, context);
                        Navigator.pop(context);
                      },
                    ),
                    Text("Remove", style: TextStyle(color: Colors.red)),
                  ],
                ),
            ],
          ),
        ],
      );
    },
  );
}

// Display profile image in a dialog
void showProfileImage(String imageUrl, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(
              width: 3, color: const Color.fromARGB(255, 71, 71, 71)),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      );
    },
  );
}

// Upload profile image to Firebase Storage
Future<void> uploadImageToFirebase(XFile image, BuildContext context) async {
  try {
    String fileName = basename(image.path);
    Reference storageRef =
        FirebaseStorage.instance.ref().child('profile_pics/$fileName');
    UploadTask uploadTask = storageRef.putFile(File(image.path));
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    String imageUrl = await snapshot.ref.getDownloadURL();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'profileImageUrl': imageUrl});
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo updated successfully!')));
  } catch (e) {
    print('Error uploading image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile photo')));
  }
}

// Remove profile image from Firebase Storage and Firestore
Future<void> removeProfileImage(
    String profileImageUrl, BuildContext context) async {
  try {
    Reference storageRef = FirebaseStorage.instance.refFromURL(profileImageUrl);
    await storageRef.delete();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'profileImageUrl': null});
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo removed successfully!')));
  } catch (e) {
    print('Error removing image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove profile photo')));
  }
}

// Build profile stats (followers, following, posts)
Widget buildProfileStats(int followers, int following, int postsCount,
    String userId, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      buildStatItem('Posts', postsCount),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FollowersFollowingScreen(userId: userId)),
        ),
        child: buildStatItem('Followers', followers),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FollowersFollowingScreen(userId: userId)),
        ),
        child: buildStatItem('Following', following),
      ),
    ],
  );
}

// Helper function to build each stat item
Widget buildStatItem(String label, int count) {
  return Column(
    children: [
      Text('$count',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
    ],
  );
}

// Build a grid of user posts
Widget buildUserPosts(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        print('Error: ${snapshot.error}'); // Log the error
        return Center(child: Text('Failed to load posts'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        print('No posts found for user: $userId'); // Log if no posts found
        return Center(child: Text('No posts yet'));
      }

      print(
          'Posts loaded: ${snapshot.data!.docs.length}'); // Log number of posts

      return GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4.0, // Increased spacing
          crossAxisSpacing: 4.0, // Increased spacing
        ),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var post = snapshot.data!.docs[index];
          var postImageUrl = post['imageUrl'] ??
              ''; // Get imageUrl, default to empty string if null

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: post.id),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
                borderRadius: BorderRadius.circular(12), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2), // Shadow position
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge, // Ensures the child is clipped
              child: postImageUrl.isNotEmpty
                  ? Image.network(
                      postImageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300], // Placeholder for missing images
                      child: Center(child: Text('No Image')),
                    ),
            ),
          );
        },
      );
    },
  );
}
