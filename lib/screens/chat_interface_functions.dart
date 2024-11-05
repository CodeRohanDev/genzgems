import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> sendMessage({
  required String senderId,
  required String receiverId,
  String? textMessage,
}) async {
  // Step 1: Prepare the message data
  Map<String, dynamic> messageData = {
    'senderId': senderId,
    'receiverId': receiverId,
    'timestamp': FieldValue.serverTimestamp(),
    'read': false,
    if (textMessage != null) 'message': textMessage,
  };

  // Step 2: Add the message to Firestore
  await FirebaseFirestore.instance.collection('messages').add(messageData);
}

void updateLastSeen(String userId) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error updating last seen: $e');
  }
}
