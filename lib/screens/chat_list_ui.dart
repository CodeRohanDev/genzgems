import 'package:flutter/material.dart';
import 'package:genzgems/screens/ai_chat_screen.dart';
import 'package:lottie/lottie.dart';
import 'chat_list_widgets.dart'; // ChatListItem component
import 'chat_list_functions.dart'; // fetchChatList function
import 'user_connections_screen.dart';
import 'chat_interface_screen.dart';

class ChatListPage extends StatefulWidget {
  final String userId;

  const ChatListPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with WidgetsBindingObserver {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false; // Flag to indicate search mode
  bool isChatSelected = false;
  String? selectedChatId; // Store selected chat ID

  void _onLongPressChat(String receiverId) {
    setState(() {
      isChatSelected = true;
      selectedChatId = receiverId;
    });
  }

  void _clearSelection() {
    setState(() {
      isChatSelected = false;
      selectedChatId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching; // Toggle search mode
      if (!_isSearching) {
        _searchQuery = ''; // Clear search query when exiting search mode
        _searchController.clear(); // Clear search field
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle:
                      TextStyle(color: const Color.fromARGB(137, 0, 0, 0)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                ),
                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text("Chat List"),
        leading: isChatSelected
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (isChatSelected)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                if (selectedChatId != null) {
                  _deleteChat(selectedChatId!);
                }
                _clearSelection();
              },
            ),
          if (!isChatSelected)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
          IconButton(
            icon: CircleAvatar(
              radius: 20,
              child: Lottie.asset(
                'assets/lemo.json',
                width: 120,
                height: 120,
              ),
            ),
            tooltip: 'AI Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIChatScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchChatList(widget.userId), // Fetch chat list stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 12, // Number of shimmer placeholders
              itemBuilder: (context, index) => ShimmerChatListItem(),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No chats available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final chatList = snapshot.data!;
          // Filter the chat list based on the search query
          final filteredChatList = chatList.where((chat) {
            final fullName = chat['fullName']?.toLowerCase() ?? '';
            return fullName.contains(_searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: filteredChatList.length,
            itemBuilder: (context, index) {
              final chat = filteredChatList[index];
              final receiverId = chat['receiverId'];

              // Check if this chat is the selected one
              final isSelected = selectedChatId == receiverId;

              return Container(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent, // Highlight selected chat
                child: ChatListItem(
                  chat: chat,
                  onTap: () {
                    if (!isChatSelected) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatInterfaceScreen(
                            userId: receiverId!,
                            senderId: widget.userId,
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // Reload chat list on return
                      });
                    } else {
                      _clearSelection();
                    }
                  },
                  onLongPress: () => _onLongPressChat(
                      receiverId!), // Handle long press to select chat
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UserConnectionsScreen(userId: widget.userId),
            ),
          );
        },
        child: Icon(Icons.group_add),
        tooltip: 'Add Connections',
      ),
    );
  }

  void _deleteChat(String receiverId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Chat'),
          content: Text('Are you sure you want to delete this chat?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteChat(widget.userId, receiverId); // Call delete function
                Navigator.of(context).pop();
                setState(() {}); // Refresh chat list
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
