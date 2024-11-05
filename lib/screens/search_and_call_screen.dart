import 'package:flutter/material.dart';
import 'package:genzgems/screens/search_and_call_functions.dart';
import 'package:genzgems/screens/search_and_call_widgets.dart';

class SearchAndCallScreen extends StatefulWidget {
  final String currentUserId; // Current user ID

  SearchAndCallScreen({required this.currentUserId});

  @override
  _SearchAndCallScreenState createState() => _SearchAndCallScreenState();
}

class _SearchAndCallScreenState extends State<SearchAndCallScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> users = []; // List of all followers and following

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch followers and following users
  }

  Future<void> _fetchUsers() async {
    List<Map<String, dynamic>> userList =
        await fetchFollowersAndFollowing(widget.currentUserId);
    setState(() {
      users = userList;
      isLoading = false;
    });
  }

  String _generateChannelId(String userId) {
    // Generate a unique channel ID, you might want to adjust this logic based on your requirements
    return '${widget.currentUserId}_$userId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search & Call"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return UserCallItem(
                  profileImageUrl: user['profileImageUrl'],
                  fullName: user['fullName'],
                  userId: user['userId'], // User ID for making calls
                  channelId: _generateChannelId(
                      user['userId']), // Generate channel ID for each user
                );
              },
            ),
    );
  }
}
