// ignore_for_file: prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genzgems/screens/Authentication/login_screen.dart';
import 'package:genzgems/screens/Profile/profile_functions.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color.fromARGB(7, 165, 210, 247),
      endDrawer: Drawer(
        shape: Border.symmetric(horizontal: BorderSide.none),
        child: ListView(padding: EdgeInsets.zero, children: <Widget>[
          SizedBox(height: 35),
          ListTile(
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings'),
                  Icon(Icons.arrow_forward_ios, size: 16)
                ]),
            onTap: () {},
          ),
          ListTile(
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Logout'),
                  Icon(Icons.arrow_forward_ios, size: 16)
                ]),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          )
        ]),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildLoadingProfileHeader();
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
          String? coverImageUrl = userData['coverImageUrl'];

          List<dynamic> followersList = userData['followers'] ?? [];
          List<dynamic> followingList = userData['following'] ?? [];
          int followersCount = followersList.length;
          int followingCount = followingList.length;
          int postsCount = userData['postsCount'] ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  buildProfileHeader(profileImageUrl, fullName, username, bio,
                      category, coverImageUrl, context),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        buildProfileStats(followersCount, followingCount,
                            postsCount, userId, context),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10, top: 10),
                              child: Text(
                                "Highlights",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                        buildHighlightSection(userId, context),
                        buildUserPosts(userId)
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildLoadingProfileHeader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 3.5,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading Profile...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class HighlightStoryScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const HighlightStoryScreen(
      {Key? key, required this.imageUrl, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
