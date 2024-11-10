// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, avoid_print, sized_box_for_whitespace, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:genzgems/screens/Profile/User%20Profile/user_profile_screen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatefulWidget {
  final String postId;
  PostDetailScreen({required this.postId});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
        appBar: AppBar(
          title: Text('Post Details'),
          backgroundColor: Colors.blueAccent,
          elevation: 10,
        ),
        body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Post not found.'));
              }

              var post = snapshot.data!;
              var postData = post.data() as Map<String, dynamic>;
              String caption = postData['caption'] ?? '';
              String imageUrl = postData['imageUrl'] ?? '';
              int likesCount = postData['likesCount'] ?? 0;
              int commentsCount = postData['commentsCount'] ?? 0;
              List<dynamic> likes = List.from(postData['likes'] ?? []);
              String postUserId = postData['userId'] ?? '';

              _isLiked = likes.contains(userId);

              return SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(postUserId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Row(children: [
                                      CircularProgressIndicator(),
                                    ]);
                                  }

                                  if (!userSnapshot.hasData ||
                                      !userSnapshot.data!.exists) {
                                    return Text('User not found');
                                  }

                                  var userData = userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                                  String fullName =
                                      userData['fullName'] ?? 'Unknown User';
                                  String username =
                                      userData['username'] ?? 'Unknown';
                                  String profilePhotoUrl =
                                      userData['profileImageUrl'] ?? '';

                                  return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          CircleAvatar(
                                            radius: 25,
                                            backgroundImage: profilePhotoUrl
                                                    .isNotEmpty
                                                ? NetworkImage(profilePhotoUrl)
                                                : AssetImage('assets/logo.png')
                                                    as ImageProvider,
                                          ),
                                          SizedBox(width: 15),
                                          Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(fullName,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16)),
                                                Text('@$username',
                                                    style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14))
                                              ])
                                        ]),
                                        IconButton(
                                          onPressed: () async {
                                            final String userId = FirebaseAuth
                                                .instance.currentUser!.uid;
                                            var postSnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection('posts')
                                                    .doc(widget.postId)
                                                    .get();

                                            if (postSnapshot.exists) {
                                              var postData = postSnapshot.data()
                                                  as Map<String, dynamic>;
                                              String postUserId =
                                                  postData['userId'];
                                              String imageUrl = postData[
                                                      'imageUrl'] ??
                                                  ''; // Ensure imageUrl is available

                                              if (userId == postUserId) {
                                                _showPostOptions(context,
                                                    widget.postId, imageUrl);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'You can only delete your own posts')),
                                                );
                                              }
                                            }
                                          },
                                          icon: Icon(Icons.more_vert),
                                          color: Colors.black,
                                        )
                                      ]);
                                }),
                            SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                caption,
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            SizedBox(height: 16),
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImagePreviewScreen(
                                          imageUrl: imageUrl),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Hero(
                                        tag: imageUrl,
                                        child: Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          height: 300,
                                          fit: BoxFit.cover,
                                        )))),
                            SizedBox(height: 16),
                            _buildPostActions(likesCount, commentsCount, likes),
                            SizedBox(height: 10),
                            Divider(),
                            _buildAddCommentSection(userId),
                            _buildCommentsSection(),
                            SizedBox(height: 10),
                          ])));
            }));
  }

  Widget _buildPostActions(
      int likesCount, int commentsCount, List<dynamic> likes) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        IconButton(
          icon:
              Icon(_isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined),
          onPressed: () => _toggleLike(likes, likesCount),
          color: _isLiked ? Colors.blue : Colors.black,
        ),
        GestureDetector(
          onTap: () => _showLikesBottomSheet(likes),
          child: Text('$likesCount Likes'),
        ),
      ]),
      Row(children: [
        IconButton(
          icon: Icon(Icons.comment_outlined),
          onPressed: () {},
          color: Colors.black,
        ),
        Text('$commentsCount Comments'),
      ]),
      Row(children: [
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () {
            _showShareBottomSheet();
          },
          color: Colors.black,
        ),
        Text('Share'),
      ])
    ]);
  }

  void _showLikesBottomSheet(List<dynamic> likes) {
    // Assuming you have a way to get the current user's ID
    String currentUserId = FirebaseAuth
        .instance.currentUser!.uid; // Adjust according to your auth setup

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
              height: MediaQuery.of(context).size.height *
                  0.5, // Set height to half of the screen
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Users Who Liked This Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .where(FieldPath.documentId, whereIn: likes)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                                child: Text('No users liked this post.'));
                          }

                          var likedUsers = snapshot.data!.docs;

                          return ListView(
                              children:
                                  List.generate(likedUsers.length, (index) {
                            var userData = likedUsers[index].data()
                                as Map<String, dynamic>;
                            String fullName = userData['fullName'] ?? 'Unknown';
                            String username = userData['username'] ??
                                'Unknown'; // Fetch the username
                            String profilePhotoUrl =
                                userData['profileImageUrl'] ?? '';
                            String userId = likedUsers[index]
                                .id; // Get the user ID for navigation

                            return GestureDetector(
                                onTap: () {
                                  // Check if the tapped user is the current user
                                  if (userId != currentUserId) {
                                    // Navigate to the selected user's profile
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UserProfileScreen(userId: userId),
                                        ));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "You're already on your profile.")),
                                    );
                                  }
                                },
                                child: Container(
                                    margin: EdgeInsets.only(
                                        bottom: 2), // Add margin between items
                                    child: ListTile(
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 2.0),
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundImage: profilePhotoUrl
                                                  .isNotEmpty
                                              ? NetworkImage(profilePhotoUrl)
                                              : AssetImage('assets/logo.png')
                                                  as ImageProvider,
                                        ),
                                        title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fullName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                  '@$username', // Display username
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ))
                                            ]))));
                          }));
                        }))
              ]));
        });
  }

  void _showShareBottomSheet() async {
    var currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    var followersList =
        List<String>.from(currentUserDoc.data()?['followers'] ?? []);
    var followingList =
        List<String>.from(currentUserDoc.data()?['following'] ?? []);

    if (followersList.isEmpty && followingList.isEmpty) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("You have no followers to share the post."),
            );
          });
      return;
    }

    List<String> allUsers = [...followersList, ...followingList];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
              height: MediaQuery.of(context).size.height *
                  0.5, // Set height to half of the screen
              padding: const EdgeInsets.all(16.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  "Share with Followers and Following",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                    child: ListView.builder(
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                              title: Text(allUsers[index]),
                              trailing: IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () {
                                    // Implement share functionality here
                                  }));
                        }))
              ]));
        });
  }

  void _toggleLike(List<dynamic> likes, int likesCount) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (_isLiked) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
        'likesCount': likesCount - 1,
      });
      setState(() {
        _isLiked = false;
      });
    } else {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
        'likesCount': likesCount + 1,
      });
      setState(() {
        _isLiked = true;
      });
    }
  }

  Widget _buildCommentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No comments yet.');
        }

        var comments = snapshot.data!.docs;

        return Container(
          height: 300, // Set a fixed height for the comments section
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              var commentData = comments[index].data() as Map<String, dynamic>;
              String commentText = commentData['comment'] ?? '';
              String commentUserId = commentData['userId'] ?? '';
              var createdAt = commentData['createdAt']?.toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(commentUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return SizedBox();
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  String fullName = userData['fullName'] ?? 'Unknown User';
                  String profilePhotoUrl = userData['profileImageUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePhotoUrl.isNotEmpty
                          ? NetworkImage(profilePhotoUrl)
                          : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    ),
                    title: Text(fullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(commentText),
                        if (createdAt != null)
                          Text(
                            timeago.format(createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddCommentSection(String userId) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _commentController,
          decoration: InputDecoration(hintText: 'Add a comment...'),
        ),
      ),
      IconButton(
        icon: Icon(Icons.send),
        onPressed: () => _addComment(userId),
      )
    ]);
  }

  void _addComment(String userId) async {
    if (_commentController.text.isEmpty) return;

    try {
      // Add the comment to the comments subcollection
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'comment': _commentController.text,
        'userId': userId,
        'createdAt': DateTime.now(),
      });

      // Increment the comments count in the post document
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'commentsCount': FieldValue.increment(1), // Increment comments count
      });

      print("Comment added and commentsCount updated successfully.");
    } catch (e) {
      print("Error adding comment: $e");
    }

    // Clear the comment text field
    _commentController.clear();
  }

  void _showPostOptions(BuildContext context, String postId, String imageUrl) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ListView(
          padding: EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('Delete Post', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Close the bottom sheet
                bool confirmDelete = await _confirmDelete(context);
                if (confirmDelete) {
                  // Pass the correct userId here
                  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  await _deletePost(postId, imageUrl, userId, context);
                }
              },
            ),
            ListTile(
              title: Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

// Show confirmation dialog for deletion
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Delete Post'),
              content: Text('Are you sure you want to delete this post?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

// Delete the post from Firestore and remove image from Storage
  Future<void> _deletePost(
    String postId,
    String imageUrl,
    String userId, // UserId to update post count
    BuildContext context,
  ) async {
    try {
      // Step 1: Fetch the current post count of the user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("User not found");
      }

      // Get the current post count of the user
      int currentPostCount = userDoc['postsCount'];

      // Step 2: Decrement the post count by 1
      int newPostCount = currentPostCount - 1;

      // Step 3: Update the user's postsCount field in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'postsCount': newPostCount,
      });

      // Step 4: Delete the post document from Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      // Step 5: If there's an image associated, delete it from Firebase Storage
      if (imageUrl.isNotEmpty) {
        final Reference storageRef =
            FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post deleted successfully!')),
        );

        // Navigate to the Profile Page after deletion
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/profile', // Ensure this route is correct
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Error deleting post: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post. Please try again.')),
        );
      }
    }
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;

  ImagePreviewScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Image Preview'),
        ),
        body: Center(
            child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained, // Scale to fit the screen
          maxScale: PhotoViewComputedScale.covered * 2, // Maximum zoom scale
          heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
        )));
  }
}
