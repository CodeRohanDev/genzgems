// ignore_for_file: prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables, prefer_final_fields, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:genzgems/screens/Chat/Chat Interface/chat_interface_screen.dart';
import 'package:genzgems/screens/Posts/post_details_screen.dart';
import 'package:genzgems/screens/Profile/User%20Profile/user_profile_functions.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  UserProfileScreen({required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    bool following = await checkIfFollowing(widget.userId);
    setState(() {
      _isFollowing = following;
    });
  }

  Future<void> _toggleFollow() async {
    bool updatedFollowingStatus =
        await toggleFollow(widget.userId, _isFollowing);
    setState(() {
      _isFollowing = updatedFollowingStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User not found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = userData['fullName'] ?? '';
          String username = userData['username'] ?? '';
          String bio = userData['bio'] ?? '';
          String profileImageUrl =
              userData['profileImageUrl'] ?? 'assets/logo.png';
          String coverImageUrl = userData['coverImageUrl'] ?? '';
          String category = userData['category'] ?? '';
          String followersCount =
              (userData['followers'] as List<dynamic>? ?? []).length.toString();
          String followingCount =
              (userData['following'] as List<dynamic>? ?? []).length.toString();

          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Cover Image with Back Button
              Stack(
                children: [
                  if (coverImageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              imageUrl: coverImageUrl,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(coverImageUrl),
                            fit: BoxFit.cover,
                            onError: (_, __) {
                              setState(() {
                                coverImageUrl = 'assets/default_cover.jpg';
                              });
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              imageUrl: 'assets/default_cover.jpg',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Image.asset('assets/default_cover.jpg'),
                      ),
                    ),
                  Positioned(
                    top: 20,
                    left: 15,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context); // Navigate back
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),
              // Profile Image and Name
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            imageUrl: profileImageUrl,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: ClipOval(
                        child: profileImageUrl.startsWith('http')
                            ? Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                width: 120, // 2 * radius
                                height: 120, // 2 * radius
                              )
                            : Image.asset(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(fullName,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('@$username',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  if (category.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.grey[300],
                      ),
                      child: Text(category,
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  SizedBox(height: 8),
                  if (bio.isNotEmpty) Text(bio, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildPostCount(widget.userId),
                        _countColumn('Followers', followersCount),
                        _countColumn('Following', followingCount),
                      ],
                    ),
                    SizedBox(height: 20),
                    _isFollowing
                        ? _buildFollowingButtons()
                        : _buildFollowButton(),
                    SizedBox(height: 20),
                    // Highlights
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Highlights', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(width: 0.1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 18),
                            child: buildUserHighlights(widget.userId),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    buildUserPosts(widget.userId),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildUserHighlights(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Stream for user highlights
      stream: getUserHighlights(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('No highlights available.'),
            ),
          );
        }

        var highlights = snapshot.data!;

        // Sort the highlights by 'createdAt' field in descending order (most recent first)
        highlights.sort((a, b) {
          var timeA = a['createdAt']
              ?.toDate(); // Convert timestamp to DateTime if necessary
          var timeB = b['createdAt']?.toDate();
          return timeB!.compareTo(timeA!); // Sort in descending order
        });

        return SizedBox(
          height: 120, // Increase height to give more space
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length,
            itemBuilder: (context, index) {
              String title = highlights[index]['title'] ?? 'Highlight';
              String imageUrl = highlights[index]['imageUrl'] ?? '';

              return GestureDetector(
                onTap: () {
                  // Navigate to ImageViewerScreen when highlight image is clicked
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        imageUrl: imageUrl,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 16), // Add spacing between items
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : AssetImage('assets/placeholder.jpg')
                                as ImageProvider,
                      ),
                      SizedBox(
                          height: 10), // Increased gap between image and title
                      Container(
                        width:
                            80, // Optional: restrict width for better text wrapping
                        alignment: Alignment.center,
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow
                              .ellipsis, // Add ellipsis for long text
                          maxLines:
                              1, // Prevent title from wrapping into multiple lines
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _toggleFollow,
          child: Text(
            'Unfollow',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatInterfaceScreen(
                  userId: widget.userId,
                  senderId: _currentUserId,
                ),
              ),
            );
          },
          child: Text(
            'Message',
            style: TextStyle(color: Colors.black),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color.fromARGB(36, 200, 230, 255), // Background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: _toggleFollow,
      child: Text(
        'Follow',
        style: TextStyle(
          color: Colors.white, // Text color
          fontSize: 16, // Font size
          fontWeight: FontWeight.bold, // Bold text
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildPostCount(String userId) {
    return StreamBuilder<int>(
      // Stream for user post count
      stream: getPostCount(userId),
      builder: (context, snapshot) {
        String postCount = snapshot.data?.toString() ?? '0';
        return _countColumn('Posts', postCount);
      },
    );
  }

  Widget _countColumn(String label, String count) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget buildUserPosts(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Stream for user posts, ordered by createdAt
      stream: getUserPosts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No posts available.'));
        }

        var posts = snapshot.data!;

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
            String postId = posts[index]['id'] ?? '';
            String imageUrl = posts[index]['imageUrl'] ?? '';
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postId: postId),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.4),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[300],
                        child: Center(child: Text('No Image')),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  ImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for image viewing
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // Remove AppBar shadow
        automaticallyImplyLeading: false, // Remove the default back arrow
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Close the image when tapped anywhere
        },
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5, // Minimum zoom out scale
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
