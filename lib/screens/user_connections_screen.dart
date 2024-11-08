import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genzgems/screens/chat_interface_screen.dart';
import 'package:genzgems/screens/search_friends_screen.dart';
import 'package:genzgems/screens/user_profile_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:uicons/uicons.dart';

class UserConnectionsScreen extends StatefulWidget {
  final String userId; // The current user's ID

  UserConnectionsScreen({required this.userId});

  @override
  _UserConnectionsScreenState createState() => _UserConnectionsScreenState();
}

class _UserConnectionsScreenState extends State<UserConnectionsScreen> {
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true; // Loading state variable

  @override
  void initState() {
    super.initState();
    _fetchFollowersAndFollowing();
  }

  // Fetching followers and following lists
  Future<void> _fetchFollowersAndFollowing() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data();
        List<String> followers =
            List<String>.from(userData?['followers'] ?? []);
        List<String> following =
            List<String>.from(userData?['following'] ?? []);

        Set<String> allConnectionsSet = {};
        allConnectionsSet.addAll(followers);
        allConnectionsSet.addAll(following);

        List<String> allConnections = allConnectionsSet.toList();

        List<Map<String, dynamic>> userDetails = [];
        for (var id in allConnections) {
          var userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .get();
          var userData = userDoc.data();

          if (userData != null) {
            userDetails.add({
              'id': id,
              'profileImageUrl': userData['profileImageUrl'] ?? '',
              'fullName': userData['fullName'] ?? 'Unknown User',
              'username': userData['username'] ?? 'Unknown',
            });
          }
        }

        userDetails.sort((a, b) => a['fullName'].compareTo(b['fullName']));

        setState(() {
          _userList = userDetails;
          _filteredList = userDetails;
          _isLoading = false; // Set loading to false once data is fetched
        });
      }
    } catch (e) {
      print('Error fetching followers and following: $e');
      setState(() {
        _isLoading = false; // Ensure loading state is false even on error
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredList = _userList.where((user) {
        return user['fullName'].toLowerCase().contains(query.toLowerCase()) ||
            user['username'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _navigateToChat(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatInterfaceScreen(
          userId: userId,
          senderId: widget.userId,
        ),
      ),
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friends',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontFamily: 'Nunito Sans',
          ),
        ),
        actions: [
          if (_userList.isNotEmpty)
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchFriendsScreen(),
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                hintStyle: TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Lottie.asset('assets/loading_animation.json',
                  height: 150)) // Show loading indicator
          : _filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Find Friends!",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchFriendsScreen(),
                            ),
                          );
                        },
                        child: Text("Search for Friends"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    final user = _filteredList[index];
                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          _navigateToUserProfile(user['id']);
                        },
                        child: CircleAvatar(
                          backgroundImage: user['profileImageUrl'] != null &&
                                  user['profileImageUrl'].isNotEmpty
                              ? NetworkImage(user['profileImageUrl'])
                              : AssetImage(
                                  'assets/logo.png',
                                ), // Replace with your asset image path
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          _navigateToUserProfile(user['id']);
                        },
                        child: Text(
                          user['fullName'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      subtitle: GestureDetector(
                        onTap: () {
                          _navigateToUserProfile(user['id']);
                        },
                        child: Text(
                          '@${user['username']}',
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(UIcons.regularStraight.message_code),
                        onPressed: () {
                          _navigateToChat(
                            user['id'],
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
