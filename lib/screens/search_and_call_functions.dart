import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchFollowersAndFollowing(
    String currentUserId) async {
  List<Map<String, dynamic>> userList = [];
  Set<String> userIdsSet = {}; // Set to track unique user IDs

  // Fetch current user document
  DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .get();

  // Fetch followers
  List<String> followers = List.from(currentUserDoc['followers'] ?? []);
  for (String followerId in followers) {
    DocumentSnapshot followerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(followerId)
        .get();
    if (followerDoc.exists) {
      // Add only if the user ID is unique
      if (!userIdsSet.contains(followerDoc.id)) {
        userIdsSet.add(followerDoc.id);
        userList.add({
          'profileImageUrl': followerDoc['profileImageUrl'] ?? '',
          'fullName': followerDoc['fullName'] ?? 'Unknown User',
          'userId': followerDoc.id, // Use the document ID as user ID
        });
      }
    }
  }

  // Fetch following
  List<String> following = List.from(currentUserDoc['following'] ?? []);
  for (String followingId in following) {
    DocumentSnapshot followingDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(followingId)
        .get();
    if (followingDoc.exists) {
      // Add only if the user ID is unique
      if (!userIdsSet.contains(followingDoc.id)) {
        userIdsSet.add(followingDoc.id);
        userList.add({
          'profileImageUrl': followingDoc['profileImageUrl'] ?? '',
          'fullName': followingDoc['fullName'] ?? 'Unknown User',
          'userId': followingDoc.id, // Use the document ID as user ID
        });
      }
    }
  }

  return userList;
}
