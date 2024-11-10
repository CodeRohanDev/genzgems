import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Stream that returns the chat list
Stream<List<Map<String, dynamic>>> fetchChatList(String userId) {
  try {
    // Stream for sent messages where the user is the sender
    Stream<QuerySnapshot> sentMessagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Stream for received messages where the user is the receiver
    Stream<QuerySnapshot> receivedMessagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Combine the two streams manually using StreamZip from async package
    return StreamZip([sentMessagesStream, receivedMessagesStream])
        .asyncMap((snapshots) async {
      QuerySnapshot sentSnapshot = snapshots[0];
      QuerySnapshot receivedSnapshot = snapshots[1];

      Map<String, Map<String, dynamic>> chatMap = {};
      Set<String> userIdsToFetch = {};

      // Collect unique user IDs from sent and received messages
      for (var doc in sentSnapshot.docs) {
        userIdsToFetch.add(doc['receiverId']);
      }
      for (var doc in receivedSnapshot.docs) {
        userIdsToFetch.add(doc['senderId']);
      }

      // Fetch user details in a single batch
      if (userIdsToFetch.isNotEmpty) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: userIdsToFetch.toList())
            .get();

        // Cache user details
        Map<String, Map<String, dynamic>> userCache = {};
        for (var userDoc in userSnapshot.docs) {
          userCache[userDoc.id] = userDoc.data() as Map<String, dynamic>;
        }

        // Process sent messages
        for (var doc in sentSnapshot.docs) {
          var receiverId = doc['receiverId'];
          if (userCache[receiverId] != null) {
            var receiverDetails = userCache[receiverId];

            // Create or update chat entry
            String chatKey = receiverId;
            chatMap.putIfAbsent(
                chatKey,
                () => {
                      'profileImageUrl':
                          receiverDetails?['profileImageUrl'] ?? '',
                      'fullName':
                          receiverDetails?['fullName'] ?? 'Unknown User',
                      'lastMessage': _formatLastMessage(doc['message']),
                      'lastMessageTime':
                          (doc['timestamp'] as Timestamp).toDate(),
                      'unreadMessagesCount': 0, // Sent messages are not unread
                      'receiverId': receiverId,
                    });

            // Update the last message and time
            DateTime currentLastMessageTime =
                chatMap[chatKey]!['lastMessageTime'];
            DateTime newMessageTime = (doc['timestamp'] as Timestamp).toDate();
            if (newMessageTime.isAfter(currentLastMessageTime)) {
              chatMap[chatKey]!['lastMessage'] =
                  _formatLastMessage(doc['message']);
              chatMap[chatKey]!['lastMessageTime'] = newMessageTime;
            }
          }
        }

        // Process received messages
        for (var doc in receivedSnapshot.docs) {
          var senderId = doc['senderId'];
          if (userCache[senderId] != null) {
            var senderDetails = userCache[senderId];

            // Create or update chat entry
            String chatKey = senderId;
            chatMap.putIfAbsent(
                chatKey,
                () => {
                      'profileImageUrl':
                          senderDetails?['profileImageUrl'] ?? '',
                      'fullName': senderDetails?['fullName'] ?? 'Unknown User',
                      'lastMessage': _formatLastMessage(doc['message']),
                      'lastMessageTime':
                          (doc['timestamp'] as Timestamp).toDate(),
                      'unreadMessagesCount': doc['read'] == false ? 1 : 0,
                      'receiverId': senderId,
                    });

            // Update the last message and time
            DateTime currentLastMessageTime =
                chatMap[chatKey]!['lastMessageTime'];
            DateTime newMessageTime = (doc['timestamp'] as Timestamp).toDate();
            if (newMessageTime.isAfter(currentLastMessageTime)) {
              chatMap[chatKey]!['lastMessage'] =
                  _formatLastMessage(doc['message']);
              chatMap[chatKey]!['lastMessageTime'] = newMessageTime;
            }
          }
        }
      }

      // Return the chat list as a list of maps
      return chatMap.entries.map((e) => e.value).toList();
    });
  } catch (error) {
    // Handle any errors that occur during fetching
    throw Exception('Failed to fetch chat list: $error');
  }
}

// Helper function to format the last message
String _formatLastMessage(String message) {
  // Check if the message contains a Firebase Storage URL
  if (message.contains("https://firebasestorage.googleapis.com")) {
    return '📷 Media'; // Return image icon with text for image URLs
  }
  return message; // Return the original message if it's not an image URL
}

// Function to delete a chat (remove messages from current user's side)
void deleteChat(String currentUserId, String chatUserId) async {
  try {
    // Delete all messages where the current user is the sender
    var sentMessages = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: chatUserId)
        .get();
    for (var doc in sentMessages.docs) {
      await doc.reference.delete();
    }

    // Delete all messages where the current user is the receiver
    var receivedMessages = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: chatUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .get();
    for (var doc in receivedMessages.docs) {
      await doc.reference.delete();
    }
  } catch (e) {
    print('Error deleting chat: $e');
  }
}

// Function to pin a chat
void pinChat(String currentUserId, String chatUserId) async {
  try {
    var userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    await userRef.update({
      'pinnedChats':
          FieldValue.arrayUnion([chatUserId]) // Add chat to pinned list
    });
  } catch (e) {
    print('Error pinning chat: $e');
  }
}
