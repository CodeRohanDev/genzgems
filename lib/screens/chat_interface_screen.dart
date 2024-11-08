// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:genzgems/screens/chat_interface_functions.dart';
import 'package:genzgems/screens/message_input_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class ChatInterfaceScreen extends StatefulWidget {
  final String userId;
  final String senderId;

  ChatInterfaceScreen({required this.userId, required this.senderId});

  @override
  _ChatInterfaceScreenState createState() => _ChatInterfaceScreenState();
}

class _ChatInterfaceScreenState extends State<ChatInterfaceScreen> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  String userFullName = '';
  String userProfileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _markMessagesAsRead();
    _preloadMessages();
  }

  Future<void> _fetchUserDetails() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      userFullName = userDoc['fullName'] ?? 'unknown user';
      // Inside the widget where you display the profile image
      Widget buildProfileImage() {
        return userProfileImageUrl.isNotEmpty
            ? CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(userProfileImageUrl),
              )
            : CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              );
      }
    }
  }

  Future<void> _preloadMessages() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot preloadedMessagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', whereIn: [widget.senderId, widget.userId])
        .where('receiverId', whereIn: [widget.senderId, widget.userId])
        .orderBy('timestamp')
        .get();

    messages = preloadedMessagesSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return {
        'id': doc.id,
        'senderId': data?['senderId'] ?? '',
        'receiverId': data?['receiverId'] ?? '',
        'message': data?['message'] ?? '',
        'timestamp': data?['timestamp'] ?? Timestamp.now(),
        'read': data?['read'] ?? false,
      };
    }).toList();

    messages
        .removeWhere((msg) => msg['message'] == null || msg['message'] == '');

    setState(() {
      isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _markMessagesAsRead() async {
    QuerySnapshot unreadMessagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: widget.senderId)
        .where('senderId', isEqualTo: widget.userId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unreadMessagesSnapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
      'message': 'This message was deleted',
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6BE1E7),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: userProfileImageUrl.isNotEmpty
                  ? NetworkImage(userProfileImageUrl)
                  : AssetImage('assets/logo.png'),
            ),
            SizedBox(width: 8),
            Text(
              userFullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Blurred background image
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/chatbg.png', // Path to your background image
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 2.5,
                      sigmaY:
                          2.5), // Adjust sigmaX and sigmaY for blur intensity
                  child: Container(
                    color: Colors.black.withOpacity(
                        0.1), // Optional overlay color to darken the background
                  ),
                ),
              ],
            ),
          ),
          // Main chat UI content
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('senderId',
                          whereIn: [widget.senderId, widget.userId])
                      .where('receiverId',
                          whereIn: [widget.senderId, widget.userId])
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Lottie.asset(
                          'assets/loading_animation.json',
                          width: 100,
                          height: 100,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No messages yet"));
                    }

                    messages = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'senderId': data['senderId'] ?? '',
                        'receiverId': data['receiverId'] ?? '',
                        'message': data['message'] ?? '',
                        'isDeleted': data['isDeleted'] ?? false,
                        'timestamp': data['timestamp'] ?? Timestamp.now(),
                        'read': data['read'] ?? false,
                      };
                    }).toList();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        bool isMe = message['senderId'] == widget.senderId;
                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),
              MessageInputWidget(
                onSendMessage: (message) async {
                  await sendMessage(
                    senderId: widget.senderId,
                    receiverId: widget.userId,
                    textMessage: message,
                  );
                  _scrollToBottom();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    bool isImageMessage = message['message'] != null &&
        message['message'].toString().startsWith('http');

    return GestureDetector(
      onLongPress: isMe
          ? () {
              _showDeleteConfirmationDialog(message['id']);
            }
          : null,
      child: Container(
        padding: EdgeInsets.only(left: isMe ? 80 : 2, right: isMe ? 2 : 80),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 3,
              color:
                  isMe ? Color(0xFFDFF7F9) : Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 12 : 2),
                topRight: Radius.circular(isMe ? 2 : 12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: message['isDeleted']
                    ? Text(
                        'This message was deleted',
                        style: TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      )
                    : isImageMessage
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImagePreviewScreen(
                                    imageUrl: message['message'],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message['message'],
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Text(
                            message['message'] ?? 'Error loading message',
                            style: TextStyle(fontSize: 16),
                          ),
              ),
            ),
            SizedBox(height: 5),
            Text(
              _formatTimestamp(message['timestamp']),
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute}';
  }

  void _showDeleteConfirmationDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await _deleteMessage(messageId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        child: Image.network(imageUrl),
      ),
    );
  }
}
