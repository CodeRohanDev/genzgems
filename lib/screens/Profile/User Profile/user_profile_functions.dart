import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> loadUserProfile(
    String userId, Function(Map<String, dynamic>) onComplete) async {
  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      onComplete({
        'fullName': userData?['fullName'] ?? '',
        'username': userData?['username'] ?? '',
        'bio': userData?['bio'] ?? '',
        'profileImageUrl': userData?['profileImageUrl'] ?? '',
        'coverImageUrl': userData?['coverImageUrl'] ?? '',
        'category': userData?['category'] ?? '',
        'followersCount': (userData?['followers'] as List).length.toString(),
        'followingCount': (userData?['following'] as List).length.toString(),
      });
    }
  } catch (error) {
    print("Error loading user profile: $error");
  }
}

Stream<List<Map<String, dynamic>>> getUserHighlights(String userId) {
  return FirebaseFirestore.instance
      .collection('highlights')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
}

Future<bool> checkIfFollowing(String userId) async {
  try {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (currentUserDoc.exists) {
      List following = currentUserDoc['following'] ?? [];
      return following.contains(userId);
    }
  } catch (error) {
    print("Error checking follow status: $error");
  }
  return false;
}

Future<bool> toggleFollow(String userId, bool isFollowing) async {
  try {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentReference currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);

    if (isFollowing) {
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([userId])
      });
      await userRef.update({
        'followers': FieldValue.arrayRemove([currentUserId])
      });
      return false;
    } else {
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([userId])
      });
      await userRef.update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });
      return true;
    }
  } catch (error) {
    print("Error toggling follow status: $error");
  }
  return isFollowing;
}

Stream<int> getPostCount(String userId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

Stream<List<Map<String, dynamic>>> getUserPosts(String userId) {
  return FirebaseFirestore.instance
      .collection('posts') // Assuming 'posts' collection is correct
      .where('userId', isEqualTo: userId) // Filter by user ID
      .orderBy('createdAt',
          descending: true) // Sort by createdAt in descending order
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  });
}
