// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:genzgems/screens/Profile/Update%20Profile/update_profile_screen.dart';
import 'package:genzgems/screens/Profile/profile_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:genzgems/screens/Followers%20and%20Following/followers_following_screen.dart';
import 'package:genzgems/screens/Posts/post_details_screen.dart';
import 'dart:io';

import 'package:shimmer/shimmer.dart';

Widget buildProfileHeader(
  String? profileImageUrl,
  String fullName,
  String username,
  String bio,
  String? category,
  String? coverImageUrl,
  BuildContext context,
) {
  final ImagePicker _picker = ImagePicker();

  // Check if profile or cover images are loading
  bool isLoading = profileImageUrl == null && coverImageUrl == null;

  return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    GestureDetector(
      onTap: () => showCoverPhotoDialog(coverImageUrl, context, _picker),
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(0),
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: coverImageUrl != null
                    ? NetworkImage(coverImageUrl)
                    : AssetImage('assets/default_cover.jpg') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: coverImageUrl == null
                ? Icon(Icons.photo, color: Colors.white, size: 50)
                : null,
          ),
          Positioned(
            right: 10,
            top: 20,
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.white,
                size: 35,
              ),
              onPressed: () {
                _showMenu(context);
              },
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: 10),

    // Shimmer effect for profile image
    isLoading
        ? Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
            ),
          )
        : GestureDetector(
            onTap: () => showProfileDialog(profileImageUrl, context, _picker),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/person3.png') as ImageProvider,
            ),
          ),

    SizedBox(width: 20),
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 150,
                  height: 20,
                  color: Colors.grey,
                ),
              )
            : Text(
                fullName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
        SizedBox(height: 1),
        isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 100,
                  height: 16,
                  color: Colors.grey,
                ),
              )
            : Text(
                '@$username',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
      ],
    ),
    SizedBox(height: 15),
    if (category != null && category.isNotEmpty)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.grey[300],
        ),
        child:
            Text(category, style: TextStyle(fontSize: 16, color: Colors.black)),
      ),
    SizedBox(height: 5),

    // Shimmer effect for bio
    isLoading
        ? Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey,
            ),
          )
        : Text(
            bio,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            maxLines: null,
            softWrap: true,
          ),
    Padding(
      padding: const EdgeInsets.only(
        left: 30,
        right: 30,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UpdateProfileScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text(
            "Edit Profile",
            style: TextStyle(
              letterSpacing: 1,
              color: Colors.black, // Text color
              fontSize: 16, // Font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  ]);
}

void _showMenu(BuildContext context) {
  Scaffold.of(context).openEndDrawer(); // Open the right-side drawer
}

Drawer buildRightDrawer(BuildContext context) {
  return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
    ListTile(
        leading: Icon(Icons.settings),
        title: Text('Settings'),
        onTap: () {
          Navigator.pop(context);
        }),
    ListTile(
        leading: Icon(Icons.logout),
        title: Text('Logout'),
        onTap: () {
          Navigator.pop(context);
        })
  ]));
}

Future<void> showCoverPhotoDialog(
    String? coverImageUrl, BuildContext context, ImagePicker picker) async {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Cover Photo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                if (coverImageUrl != null)
                  Column(children: [
                    IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          showCoverImage(coverImageUrl, context);
                        }),
                    Text("View", style: TextStyle(color: Colors.blue))
                  ]),
                Column(
                  children: [
                    IconButton(
                        icon: Icon(Icons.edit, color: Colors.green),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            CroppedFile? croppedImage =
                                await cropImage(image.path);
                            if (croppedImage != null) {
                              // Convert CroppedFile to File
                              File imageFile = File(croppedImage.path);
                              await uploadCoverImageToFirebase(
                                  imageFile, context);
                              Navigator.pop(context);
                            }
                          }
                        }),
                    Text("Edit", style: TextStyle(color: Colors.green)),
                  ],
                ),
                if (coverImageUrl != null)
                  Column(children: [
                    IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          removeCoverImage(coverImageUrl, context);
                          Navigator.pop(context);
                        }),
                    Text("Remove", style: TextStyle(color: Colors.red))
                  ])
              ])
            ]);
      });
}

Future<void> uploadCoverImageToFirebase(
    File image, BuildContext context) async {
  try {
    String fileName = basename(image.path);
    Reference storageRef =
        FirebaseStorage.instance.ref().child('cover_photos/$fileName');
    UploadTask uploadTask = storageRef.putFile(image);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Uploading cover photo...")
                  ])));
        });
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    String coverImageUrl = await snapshot.ref.getDownloadURL();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'coverImageUrl': coverImageUrl});
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cover photo updated successfully!')));
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Failed to update cover photo')));
  }
}

Future<void> removeCoverImage(
    String coverImageUrl, BuildContext context) async {
  try {
    Reference storageRef = FirebaseStorage.instance.refFromURL(coverImageUrl);
    await storageRef.delete();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'coverImageUrl': null});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cover photo removed successfully!')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove cover photo')));
    }
  }
}

void showCoverImage(String imageUrl, BuildContext context) {
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
                child: Image.network(imageUrl, fit: BoxFit.contain)));
      });
}

Future<void> showProfileDialog(
    String? profileImageUrl, BuildContext context, ImagePicker picker) async {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Profile Photo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                if (profileImageUrl != null)
                  Column(children: [
                    IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          showProfileImage(profileImageUrl, context);
                        }),
                    Text("View", style: TextStyle(color: Colors.blue)),
                  ]),
                Column(children: [
                  IconButton(
                      icon: Icon(Icons.edit, color: Colors.green),
                      onPressed: () async {
                        final XFile? image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          CroppedFile? croppedImage =
                              await cropImage(image.path);
                          if (croppedImage != null) {
                            // Convert CroppedFile to File
                            File imageFile = File(croppedImage.path);
                            await uploadImageToFirebase(imageFile, context);
                            Navigator.pop(context);
                          }
                        }
                      }),
                  Text("Edit", style: TextStyle(color: Colors.green))
                ]),
                if (profileImageUrl != null)
                  Column(children: [
                    IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          removeProfileImage(profileImageUrl, context);
                          Navigator.pop(context);
                        }),
                    Text("Remove", style: TextStyle(color: Colors.red))
                  ])
              ])
            ]);
      });
}

Future<CroppedFile?> cropImage(String imagePath) async {
  return await ImageCropper().cropImage(sourcePath: imagePath, uiSettings: [
    AndroidUiSettings(
        lockAspectRatio: false,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        hideBottomControls: false,
        showCropGrid: true,
        cropFrameColor: Colors.blue,
        toolbarTitle: 'Adjust Crop Area'),
    IOSUiSettings(
        aspectRatioLockEnabled: true,
        minimumAspectRatio: 1.0,
        hidesNavigationBar: true)
  ]);
}

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
                child: Image.network(imageUrl, fit: BoxFit.contain)));
      });
}

Future<void> uploadImageToFirebase(File image, BuildContext context) async {
  try {
    String fileName = basename(image.path);
    Reference storageRef =
        FirebaseStorage.instance.ref().child('profile_pics/$fileName');
    UploadTask uploadTask = storageRef.putFile(image);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Uploading photo...")
                  ])));
        });
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {});

    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    String imageUrl = await snapshot.ref.getDownloadURL();

    final String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'profileImageUrl': imageUrl});

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo updated successfully!')));
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile photo')));
  }
}

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

    // Check if the widget is still mounted before showing the snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo removed successfully!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove profile photo')),
      );
    }
  }
}

Widget buildProfileStats(int followers, int following, int postsCount,
    String userId, BuildContext context) {
  return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(child: buildStatItem('Posts', postsCount)),
        VerticalDivider(color: Colors.grey.shade300, thickness: 1.5, width: 20),
        Expanded(
            child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FollowersFollowingScreen(userId: userId))),
                child: buildStatItem('Followers', followers))),
        VerticalDivider(color: Colors.grey.shade300, thickness: 1.5, width: 20),
        Expanded(
            child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FollowersFollowingScreen(userId: userId))),
                child: buildStatItem('Following', following)))
      ]));
}

Widget buildStatItem(String label, int count) {
  return Column(
      mainAxisAlignment:
          MainAxisAlignment.center, // Vertically center the content
      children: [
        Text('$count',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600]))
      ]);
}

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
          return Center(child: Text('Failed to load posts'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No posts yet'));
        }

        return GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              var postImageUrl = post['imageUrl'] ?? '';

              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PostDetailScreen(postId: post.id)));
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.4), width: 1),
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(2, 2))
                          ]),
                      clipBehavior: Clip.hardEdge,
                      child: postImageUrl.isNotEmpty
                          ? Image.network(postImageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[300],
                              child: Center(child: Text('No Image')))));
            });
      });
}

Widget buildHighlightSection(String userId, BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('highlights')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt',
            descending: true) // Sort by createdAt in descending order
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      // If no highlights are found, show the add button
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 0.1)),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor:
                                const Color.fromARGB(157, 89, 0, 255),
                            child: IconButton(
                              onPressed: () async {
                                await _addHighlight(context, userId);
                              },
                              icon: Icon(
                                Icons.add,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Text("Add Highlight"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      var highlights = snapshot.data!.docs;

      return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 0.1)),
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Add Highlight button on the left side of the row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Color.fromARGB(157, 89, 0, 255),
                              child: IconButton(
                                onPressed: () async {
                                  await _addHighlight(context, userId);
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Text("Add Highlight"),
                        ],
                      ),
                    ),
                    // Display highlights sorted by time
                    ...highlights.map((highlight) {
                      var highlightData =
                          highlight.data() as Map<String, dynamic>;
                      String? imageUrl = highlightData['imageUrl'];
                      String title = highlightData['title'] ?? 'No Title';
                      String highlightId = highlight.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HighlightStoryScreen(
                                  imageUrl: imageUrl ?? '',
                                  title: title,
                                ),
                              ),
                            );
                          },
                          onLongPress: () async {
                            bool? shouldDelete =
                                await _showDeleteDialog(context);
                            if (shouldDelete == true) {
                              await _deleteHighlight(highlightId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Highlight deleted')),
                              );
                            }
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: imageUrl != null
                                    ? NetworkImage(imageUrl)
                                    : AssetImage('assets/logo.png')
                                        as ImageProvider,
                              ),
                              SizedBox(height: 5),
                              // Centered title below the image
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: Text(
                                  title,
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<bool?> _showDeleteDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Text(
              'Delete Highlight',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this highlight? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false); // Cancel
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300], // Light grey for cancel button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Confirm deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // Red for delete button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteHighlight(String highlightId) async {
  try {
    // Delete the highlight document from Firestore
    await FirebaseFirestore.instance
        .collection('highlights')
        .doc(highlightId)
        .delete();
  } catch (e) {
    print("Error deleting highlight: $e");
  }
}

Future<void> _addHighlight(BuildContext context, String userId) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile =
      await _picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) {
    return; // If no image was selected
  }

  // Crop the image
  File? croppedFile = await _cropImage(File(pickedFile.path));
  if (croppedFile == null) {
    return; // If image cropping was canceled
  }

  String? title = await _showTitleDialog(context);
  if (title == null || title.isEmpty) {
    return; // If no title was entered
  }

  // Show a progress dialog while uploading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor, // Accent color
              strokeWidth: 3.5,
            ),
            SizedBox(height: 24),
            Text(
              "Uploading Highlight...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  try {
    // Upload image to Firebase Storage
    TaskSnapshot uploadTask = await FirebaseStorage.instance
        .ref('highlights/${DateTime.now().millisecondsSinceEpoch}.jpg')
        .putFile(croppedFile);

    String imageUrl = await uploadTask.ref.getDownloadURL();

    // Add highlight info to Firestore
    await FirebaseFirestore.instance.collection('highlights').add({
      'userId': userId,
      'imageUrl': imageUrl,
      'title': title,
      'createdAt': Timestamp.now(),
    });

    // Dismiss progress dialog
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Highlight added')));
  } catch (e) {
    // Dismiss progress dialog if an error occurs
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add highlight. Please try again.')),
    );
  }
}

Future<File?> _cropImage(File imageFile) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.deepOrange,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
      ),
      IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
    ],
  );
  return croppedFile != null ? File(croppedFile.path) : null;
}

Future<String?> _showTitleDialog(BuildContext context) async {
  TextEditingController titleController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Highlight Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Enter title',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, titleController.text); // Save title
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    },
  );
}
