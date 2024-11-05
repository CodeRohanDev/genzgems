import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart'; // Import the user profile screen

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  // Function to search for users based on username or fullname
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      String lowerQuery = query.toLowerCase();

      // Fetch all users from Firestore
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;

        // Check if either fullName or username contains the search term
        if (userData['fullName'].toLowerCase().contains(lowerQuery) ||
            userData['username'].toLowerCase().contains(lowerQuery)) {
          users.add({
            'profileImageUrl': userData['profileImageUrl'] ?? '',
            'fullName': userData['fullName'] ?? 'Unknown User',
            'username': userData['username'] ?? 'Unknown',
            'userId': doc.id, // Add user ID to navigate to their profile
          });
        }
      }

      // Sort alphabetically by full name
      users.sort((a, b) => a['fullName'].compareTo(b['fullName']));

      setState(() {
        _searchResults = users;
      });
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search for Friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (query) {
                searchUsers(query); // Call search function when text changes
              },
              decoration: InputDecoration(
                labelText: 'Search by Full Name or Username',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Display search results
            _searchResults.isEmpty
                ? Center(child: Text("No results found"))
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(user['profileImageUrl']),
                          ),
                          title: Text(user['fullName']),
                          subtitle: Text('@${user['username']}'),
                          onTap: () async {
                            // Get the current user's ID (profileOwnerId)

                            // Get the selected user's ID (userId)
                            String selectedUserId = user['userId'];

                            // Navigate to the user profile screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfileScreen(userId: selectedUserId),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
