// ignore_for_file: prefer_const_literals_to_create_immutables, use_build_context_synchronously, avoid_print, unused_element

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genzgems/screens/login_screen.dart';
import 'package:genzgems/screens/profile_functions.dart'; // Import the helper functions
import 'package:genzgems/screens/update_profile_screen.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 20,
                  width: 100,
                  color: Colors.grey[300],
                ),
              );
            }
            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              return Text(userData['username'] ?? 'Username');
            }
            return Text('Username');
          },
        ),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        shape: Border.symmetric(horizontal: BorderSide.none),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 35,
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Space between title and suffix
                children: [
                  Text('Edit Profile'),
                  Icon(Icons.arrow_forward_ios, size: 16), // Suffix icon
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Space between title and suffix
                children: [
                  Text('Settings'),
                  Icon(Icons.arrow_forward_ios, size: 16), // Suffix icon
                ],
              ),
              onTap: () {
                // Navigate to settings screen
                // You will implement the SettingsScreen separately
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Space between title and suffix
                children: [
                  Text('Logout'),
                  Icon(Icons.arrow_forward_ios, size: 16), // Suffix icon
                ],
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context); // Close the drawer
                // Navigate back to login screen or home
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildShimmerProfileHeader();
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Profile data not found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String? profileImageUrl = userData['profileImageUrl'];
          String fullName = userData['fullName'] ?? 'Full Name';
          String username = userData['username'] ?? 'Username';
          String bio = userData['bio'] ?? 'No bio available';
          String? category = userData['category'];

          List<dynamic> followersList = userData['followers'] ?? [];
          List<dynamic> followingList = userData['following'] ?? [];
          int followersCount = followersList.length;
          int followingCount = followingList.length;
          int postsCount = userData['postsCount'] ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  buildProfileHeader(profileImageUrl, fullName, username, bio,
                      category, context),
                  const SizedBox(height: 20),
                  buildProfileStats(followersCount, followingCount, postsCount,
                      userId, context),
                  const SizedBox(height: 20),
                  buildUserPosts(userId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildShimmerProfileHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 20,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  } catch (e) {
    print('Logout failed: $e');
  }
}
