// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:genzgems/screens/chat_interface_screen.dart';
import 'package:genzgems/screens/post_details_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId; // User ID passed from the search results

  UserProfileScreen({required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _fullName = '';
  String _username = '';
  String _bio = '';
  String _profileImageUrl = '';
  String _followersCount = '0';
  String _followingCount = '0';
  bool _isLoading = true;
  bool _isFollowing = false;
  String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkIfFollowing();
  }

  // Load user profile data from Firestore
  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        // Safely access user data
        final userData = userDoc.data() as Map<String, dynamic>?; // Cast to map

        setState(() {
          _fullName = userData?['fullName'] ?? '';
          _username = userData?['username'] ?? '';
          _bio = userData?['bio'] ?? '';

          // Check if the 'profileImageUrl' field exists and is not null or empty
          if (userData != null &&
              userData.containsKey('profileImageUrl') &&
              (userData['profileImageUrl'] as String).isNotEmpty) {
            _profileImageUrl = userData['profileImageUrl'];
          } else {
            _profileImageUrl =
                'assets/logo.png'; // Use asset path for default image
          }

          _followersCount = (userData?['followers'] as List).length.toString();
          _followingCount = (userData?['following'] as List).length.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print("Error loading user profile: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if the current user is following the profile user
  Future<void> _checkIfFollowing() async {
    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (currentUserDoc.exists) {
        List following = currentUserDoc['following'] ?? [];
        setState(() {
          _isFollowing = following.contains(widget.userId);
        });
      }
    } catch (error) {
      print("Error checking follow status: $error");
    }
  }

  // Toggle follow/unfollow
  Future<void> _toggleFollow() async {
    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentReference currentUserRef =
          FirebaseFirestore.instance.collection('users').doc(_currentUserId);

      if (_isFollowing) {
        // Unfollow user
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([widget.userId])
        });
        await userRef.update({
          'followers': FieldValue.arrayRemove([_currentUserId])
        });
        setState(() {
          _isFollowing = false;
          _followersCount = (int.parse(_followersCount) - 1).toString();
        });
      } else {
        // Follow user
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([widget.userId])
        });
        await userRef.update({
          'followers': FieldValue.arrayUnion([_currentUserId])
        });
        setState(() {
          _isFollowing = true;
          _followersCount = (int.parse(_followersCount) + 1).toString();
        });
      }
    } catch (error) {
      print("Error toggling follow status: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_username)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  child: ClipOval(
                    child: _profileImageUrl.startsWith('http')
                        ? Image.network(
                            _profileImageUrl,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/logo.png', // fallback in case of network error
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          )
                        : Image.asset(
                            _profileImageUrl,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _fullName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _bio,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                // Followers, Following, and Posts Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _countColumn('Followers', _followersCount),
                    _countColumn('Following', _followingCount),
                    _buildPostCount(
                        widget.userId), // Dynamically fetch post count
                  ],
                ),
                SizedBox(height: 20),
                // Follow/Unfollow Button
                _isFollowing ? _buildFollowingButtons() : _buildFollowButton(),
                SizedBox(height: 20),
                // Display Posts using StreamBuilder
                _buildUserPosts(widget.userId),
              ],
            ),
    );
  }

  Widget _buildFollowingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 170, // Adjust the width as needed
          child: ElevatedButton(
            onPressed: _toggleFollow,
            child: Text('Unfollow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ),
        SizedBox(
          width: 170, // Adjust the width as needed
          child: ElevatedButton(
            onPressed: () {
              // Navigate to the chat interface with the user
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatInterfaceScreen(
                    userId:
                        widget.userId, // ID of the user you are chatting with
                    senderId: _currentUserId, // ID of the current user
                  ),
                ),
              );
            },
            child: Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: _toggleFollow,
      child: Text('Follow'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildPostCount(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _countColumn('Posts', '0');
        }
        var postCount = snapshot.data!.docs.length.toString();
        return _countColumn('Posts', postCount);
      },
    );
  }

  Widget _countColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildUserPosts(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No posts available.'));
        }
        var posts = snapshot.data!.docs;
        return GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var post = posts[index];
            String postId = post.id; // Get the post ID
            String imageUrl = post['imageUrl'];

            return GestureDetector(
              onTap: () {
                // Navigate to the PostDetailScreen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postId: postId),
                  ),
                );
              },
              child: Image.network(imageUrl, fit: BoxFit.cover),
            );
          },
        );
      },
    );
  }
}
