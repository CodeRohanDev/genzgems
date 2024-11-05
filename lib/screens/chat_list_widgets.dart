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
        color: Colors.transparent,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: (chat['profileImageUrl'] != null &&
                    chat['profileImageUrl'].isNotEmpty)
                ? NetworkImage(chat['profileImageUrl'])
                : AssetImage(
                    'assets/logo.png'), // Path to your default image asset
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
                    ? "${chat['lastMessageTime'].day}/${chat['lastMessageTime'].month}/${chat['lastMessageTime'].year} "
                        "${chat['lastMessageTime'].hour}:${chat['lastMessageTime'].minute.toString().padLeft(2, '0')}"
                    : '',
                style: TextStyle(fontSize: 12),
              ),
              if (chat['unreadMessagesCount'] > 0)
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red,
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
