import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges; // Import the badges package with an alias
import 'package:athlosight/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final void Function(int) updateUnreadCount; // Corrected signature

  const ChatListScreen({ required this.updateUnreadCount}); // Pass the updateUnreadCount callback

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, // Remove the default back arrow
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chatDocs = snapshot.data!.docs;
          if (chatDocs.isEmpty) {
            return const Center(child: Text('No chats found.'));
          }
return ListView.builder(
  itemCount: chatDocs.length,
  itemBuilder: (context, index) {
    final reversedIndex = chatDocs.length - 1 - index; // Calculate reversed index

    final chatData = chatDocs[reversedIndex].data() as Map<String, dynamic>?;

    if (chatData == null) {
      return const SizedBox.shrink();
    }
    final userId = chatData['userId'];
    final unreadCount = chatData['unreadCount'] as int? ?? 0; // Cast to int

    // Fetch user data from 'users' collection based on the 'userId'
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const SizedBox.shrink();
        }

        final username = userData['username'];
        final profileImageUrl = userData['profileImageUrl'];

        return ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(profileImageUrl),
          ),
          title: badges.Badge(
            badgeContent: Text(
              unreadCount > 0 ? unreadCount.toString() : '', // Display unreadCount if greater than 0
              style: TextStyle(color: Colors.white),
            ),
            child: Text(
              username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          onTap: () {
            // Navigate to the chat screen when a user is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(userId: userId,         
),
              ),
            );
          },
        );
      },
    );
  },
);

        },
      ),
    );
  }
}
