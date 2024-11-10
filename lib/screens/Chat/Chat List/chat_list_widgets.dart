// ignore_for_file: use_key_in_widget_constructors, use_super_parameters

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress; // Add onLongPress callback

  const ChatListItem({
    Key? key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // Handle long press
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: const Color.fromARGB(255, 141, 141, 141), width: 0.5),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: (chat['profileImageUrl'] != null &&
                    chat['profileImageUrl'].isNotEmpty)
                ? NetworkImage(chat['profileImageUrl'])
                : AssetImage(
                    'assets/person3.png',
                  ) as ImageProvider,
            radius: 25,
          ),
          title: Text(
            chat['fullName'] ?? 'Unknown User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            chat['lastMessage'] ?? 'No message available',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                chat['lastMessageTime'] != null
                    ? (() {
                        final DateTime now = DateTime.now();
                        final DateTime lastMessageTime =
                            chat['lastMessageTime'];
                        final Duration difference =
                            now.difference(lastMessageTime);

                        if (difference.inHours < 24 &&
                            now.day == lastMessageTime.day) {
                          // Show only time if within the last 24 hours of the same day
                          return "${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}";
                        } else if (difference.inDays == 1 ||
                            (difference.inHours < 48 &&
                                now.day != lastMessageTime.day)) {
                          // Show "Yesterday" if the message was sent yesterday
                          return "Yesterday";
                        } else {
                          // Show date for older messages
                          return "${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}";
                        }
                      })()
                    : '',
                style: TextStyle(fontSize: 12),
              ),
              if (chat['unreadMessagesCount'] > 0)
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 127, 255, 131),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    chat['unreadMessagesCount'].toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerChatListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
        ),
        title: Container(
          width: 100,
          height: 15,
          color: Colors.grey[300],
        ),
        subtitle: Container(
          width: 150,
          height: 15,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
