import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genzgems/screens/Profile/User%20Profile/user_profile_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;

  FollowersFollowingScreen({required this.userId});

  @override
  _FollowersFollowingScreenState createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];
  bool isLoading = true;
  List<String> currentUserFollowing = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFollowersAndFollowing();
  }

  Future<void> _fetchFollowersAndFollowing() async {
    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      currentUserFollowing =
          List<String>.from(currentUserDoc['following'] ?? []);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      List<String> followersIds = List<String>.from(userDoc['followers'] ?? []);
      List<String> followingIds = List<String>.from(userDoc['following'] ?? []);

      if (followersIds.length > 10) followersIds = followersIds.sublist(0, 10);
      if (followingIds.length > 10) followingIds = followingIds.sublist(0, 10);

      QuerySnapshot followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: followersIds)
          .get();
      followers = followersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'userId': doc.id,
          'fullName': data?['fullName'] ?? 'Unknown',
          'profileImageUrl': data != null && data.containsKey('profileImageUrl')
              ? data['profileImageUrl']
              : 'assets/logo.png',
        };
      }).toList();

      QuerySnapshot followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();
      following = followingSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'userId': doc.id,
          'fullName': data?['fullName'] ?? 'Unknown',
          'profileImageUrl': data != null && data.containsKey('profileImageUrl')
              ? data['profileImageUrl']
              : 'assets/logo.png',
        };
      }).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _followUser(String targetUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'following': FieldValue.arrayUnion([targetUserId])
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .update({
        'followers': FieldValue.arrayUnion([widget.userId])
      });

      setState(() {
        currentUserFollowing.add(targetUserId);
        final newFollowingUser = followers.firstWhere(
            (user) => user['userId'] == targetUserId,
            orElse: () => {});
        if (newFollowingUser.isNotEmpty) {
          following.add(newFollowingUser);
        }
      });
    } catch (e) {}
  }

  Future<void> _unfollowUser(String targetUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'following': FieldValue.arrayRemove([targetUserId])
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .update({
        'followers': FieldValue.arrayRemove([widget.userId])
      });

      setState(() {
        currentUserFollowing.remove(targetUserId);
        following.removeWhere((user) => user['userId'] == targetUserId);
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFollowersList(),
                _buildFollowingList(),
              ],
            ),
    );
  }

  Widget _buildFollowersList() {
    if (followers.isEmpty) {
      return Center(child: Text('No followers yet.'));
    }
    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final follower = followers[index];
        bool isFollowing = currentUserFollowing.contains(follower['userId']);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: follower['profileImageUrl'] != null &&
                    follower['profileImageUrl'] != 'assets/logo.png'
                ? NetworkImage(follower['profileImageUrl'])
                : AssetImage('assets/logo.png') as ImageProvider,
          ),
          title: Text(follower['fullName']),
          trailing: ElevatedButton(
            onPressed: () {
              if (isFollowing) {
                _unfollowUser(follower['userId']);
              } else {
                _followUser(follower['userId']);
              }
            },
            child: Text(isFollowing ? 'Unfollow' : 'Follow'),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserProfileScreen(userId: follower['userId']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingList() {
    if (following.isEmpty) {
      return Center(child: Text('No following yet.'));
    }
    return ListView.builder(
      itemCount: following.length,
      itemBuilder: (context, index) {
        final followee = following[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: followee['profileImageUrl'] != null
                ? NetworkImage(followee['profileImageUrl'])
                : AssetImage('assets/logo.png') as ImageProvider,
          ),
          title: Text(followee['fullName']),
          trailing: ElevatedButton(
            onPressed: () {
              _unfollowUser(followee['userId']);
            },
            child: Text('Unfollow'),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserProfileScreen(userId: followee['userId']),
              ),
            );
          },
        );
      },
    );
  }
}
