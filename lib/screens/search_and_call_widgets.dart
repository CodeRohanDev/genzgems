// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

class UserCallItem extends StatelessWidget {
  final String profileImageUrl;
  final String fullName;
  final String userId;
  final String channelId;

  UserCallItem({
    required this.profileImageUrl,
    required this.fullName,
    required this.userId,
    required this.channelId,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          profileImageUrl.isNotEmpty
              ? profileImageUrl
              : 'assets/default_profile.png',
        ),
      ),
      title: Text(fullName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
              _makeCall(context, true);
            },
          ),
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              _makeCall(context, false);
            },
          ),
        ],
      ),
    );
  }

  void _makeCall(BuildContext context, bool isVideoCall) {}
}
