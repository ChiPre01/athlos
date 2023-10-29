import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:athlosight/screens/user_profile_screen.dart';
import 'package:athlosight/screens/my_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

void _performSearch(String searchTerm) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser != null) {
    final userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();
    final currentUserUsername = userData['username'] as String;
    
    if (searchTerm == currentUserUsername) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyProfileScreen(userProfileImageUrl: '',),
        ),
      );
      return; // Exit the function early if it's a self-search.
    }
  }
  
  final querySnapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('username', isGreaterThanOrEqualTo: searchTerm)
    .where('username', isLessThan: searchTerm + 'z')
    .get();

  setState(() {
    _searchResults = querySnapshot.docs;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
  backgroundColor: Colors.white, // Set the background color to white
  automaticallyImplyLeading: false, // Remove the default back arrow
  title: Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(
          'assets/IMG-20230529-WA0107.jpg',
          height: 30,
          width: 30,
        ),
      ),
      const SizedBox(width: 8), // Add spacing between the image and title
      Text(
        'User Search',
        style: TextStyle(
          color: Colors.deepPurple, // Set the text color to deep purple
        ),
      ),
    ],
  ),
),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _performSearch(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search by username',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final userData = _searchResults[index].data() as Map<String, dynamic>;
                final username = userData['username'];
                final profileImageUrl = userData['profileImageUrl'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(profileImageUrl),
                    radius: 24,
                  ),
                  title: Text(username),
                onTap: () {
  final userId = _searchResults[index].id;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UserProfileScreen(userId: userId),
    ),
  );
},

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
