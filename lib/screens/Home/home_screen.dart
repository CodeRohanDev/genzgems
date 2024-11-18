// home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_final_fields, use_build_context_synchronously

import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:genzgems/screens/Chat/Chat%20List/chat_list_ui.dart';
import 'package:genzgems/screens/Face%20Filters/face_filters.dart';
import 'package:genzgems/screens/Profile/profile_screen.dart';
import 'package:genzgems/screens/Posts/upload_post_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  List<Widget> _pages = <Widget>[];

  @override
  void initState() {
    super.initState();

    // Get the current user ID from Firebase Authentication
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      _pages = [
        FaceFilters(),
        ChatListPage(userId: userId),
        ProfileScreen(),
        UploadPostPage(),
        Center(child: Text('Calls'))
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Home Screen'),
      //   actions: [
      //     IconButton(
      //       icon: Icon(
      //         themeNotifier.isDarkTheme ? Icons.nights_stay : Icons.wb_sunny,
      //       ),
      //       onPressed: () {
      //         themeNotifier.toggleTheme(); // Toggle theme
      //       },
      //     ),
      //     IconButton(
      //       icon: Icon(Icons.logout),
      //       onPressed: () => _logout(context),
      //     ),
      //   ],
      // ),
      body: _pages.isNotEmpty
          ? _pages[_selectedIndex]
          : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        showElevation: true,
        onItemSelected: _onItemTapped,
        items: [
          FlashyTabBarItem(
            icon: Icon(Icons.camera, size: 25),
            title: Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontFamily: 'Nunito Sans'),
            ),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.chat, size: 25),
            title: Text(
              'Chats',
              style: TextStyle(fontSize: 18, fontFamily: 'Nunito Sans'),
            ),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.person, size: 25),
            title: Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontFamily: 'Nunito Sans'),
            ),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.upload, size: 25),
            title: Text(
              'Upload',
              style: TextStyle(fontSize: 18, fontFamily: 'Nunito Sans'),
            ),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.call, size: 25),
            title: Text(
              'Calls',
              style: TextStyle(fontSize: 18, fontFamily: 'Nunito Sans'),
            ),
          ),
        ],
      ),
    );
  }
}
