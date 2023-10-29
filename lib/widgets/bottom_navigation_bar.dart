import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadMessageCount;
  final String profileImageUrl; // Add the profile image URL

  const BottomNavigationBarWidget({
    required this.currentIndex,
    required this.onTap,
    required this.unreadMessageCount,
    required this.profileImageUrl, // Pass the profile image URL
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.deepPurple,
      currentIndex: currentIndex,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Create Content',
        ),
        BottomNavigationBarItem(
          icon: badges.Badge(
            badgeContent: Text(
              unreadMessageCount > 0 ? unreadMessageCount.toString() : '',
              style: TextStyle(color: Colors.white),
            ),
            child: Icon(Icons.mail),
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: CircleAvatar(
            backgroundImage: NetworkImage(profileImageUrl),
            radius: 15, // Adjust the radius as needed
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
