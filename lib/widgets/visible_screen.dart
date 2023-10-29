import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:athlosight/screens/add_post_screen.dart';
import 'package:athlosight/screens/chat_list_screen.dart';
import 'package:athlosight/screens/home_screen.dart';
import 'package:athlosight/screens/my_profile_screen.dart';
import 'package:athlosight/screens/search_screen.dart';
import 'package:athlosight/widgets/bottom_navigation_bar.dart';

class VisibleScreen extends StatefulWidget {
  final int initialIndex;

  const VisibleScreen({
    Key? key,
    required this.initialIndex, required String userProfileImageUrl,
  }) : super(key: key);

  @override
  _VisibleScreenState createState() => _VisibleScreenState();
}

class _VisibleScreenState extends State<VisibleScreen> {
  int _currentIndex = 0;
  int _unreadMessageCount = 0;
  String userProfileImageUrl = ''; // Add userProfileImageUrl variable

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    fetchUserProfileImageUrl(); // Fetch the user's profile image URL

    // Initialize _screens here after setUnreadCount is defined
    _screens = [
      HomeScreen(),
      SearchScreen(),
      AddPostScreen(),
      ChatListScreen(updateUnreadCount: setUnreadCount,),
      MyProfileScreen(userProfileImageUrl: userProfileImageUrl), // Pass userProfileImageUrl
    ];
  }

  void setUnreadCount(int count) {
    setState(() {
      _unreadMessageCount = count;
    });
  }

  Future<void> fetchUserProfileImageUrl() async {
    // Fetch the user's profile image URL and update the userProfileImageUrl variable
    // You can use the code mentioned in previous responses to fetch the URL
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final profileImageUrl = userDoc.get('profileImageUrl');

      setState(() {
        userProfileImageUrl = profileImageUrl;
      });
    }
  }

  List<Widget> _screens = []; // Initialize _screens

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        unreadMessageCount: _unreadMessageCount,
        profileImageUrl: userProfileImageUrl, // Pass the user's profile image URL
      ),
    );
  }
}
