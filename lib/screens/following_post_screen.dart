import 'package:athlosight/screens/notifications_screen.dart';
import 'package:athlosight/screens/sign_up_screen.dart';
import 'package:athlosight/widgets/visible_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:chewie/chewie.dart';
import 'package:athlosight/screens/comment_screen.dart';
import 'package:athlosight/screens/my_profile_screen.dart';
import 'package:athlosight/screens/user_profile_screen.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationBarWidget({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
       backgroundColor: Colors.deepPurple,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: const [
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
          label: 'Add Post',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Chat List',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Profile',
        ),
      ],
    );
  }
}

class FollowingPostScreen extends StatefulWidget {
  const FollowingPostScreen({Key? key}) : super(key: key);

  @override
  State<FollowingPostScreen> createState() => _FollowingPostScreenState();
}

class User {
  final String profileImageUrl;
  final String username;
  final String country;
  final String age;
  final String userId;

  User({
    required this.profileImageUrl,
    required this.username,
    required this.country,
    required this.age,
    required this.userId,
  });
}

class _FollowingPostScreenState extends State<FollowingPostScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  Map<String, ChewieController> chewieControllers = {};
  final logger = Logger();
  final Set<String> deletedPostIds = {};
  List<User> usersList = [];
  String? currentUserId;
  String? filterAge;
  String? filterSport;
  String? filterCountry;
  String? filterLevel;
  String? filterRole;
    String? filterAthleteGender;

  List<String> followingUserIds = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchUserData();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _fetchUserData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      usersList = usersSnapshot.docs.map((userDoc) {
        final userData = userDoc.data();
        return User(
          profileImageUrl: userData['profileImageUrl'] ?? '',
          username: userData['username'] ?? '',
          country: userData['country'] ?? '',
          age: userData['age']?.toString() ?? '',
          userId: userDoc.id,
        );
      }).toList();
    } catch (e) {
      print('Error fetching user data: $e');
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final followingSnapshot = await _firestore.collection('users').doc(currentUser.uid).collection('following').get();
        followingUserIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      }

      final postsSnapshot = await _firestore.collection('posts').where('uid', whereIn: followingUserIds).get();
      final posts = postsSnapshot.docs;
      print('Fetched ${posts.length} posts');
    } catch (e) {
      print('Error fetching posts data: $e');
    }

    setState(() {});
  }

  @override
  void dispose() {
    final List<ChewieController> controllerValues = chewieControllers.values.toList();
    for (final controller in controllerValues) {
      controller.dispose();
    }
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }
    // Add the signOut method
Future<void> _signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    print('User signed out successfully');
    // Navigate to the SignUpScreen after signing out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpScreen(), // Replace SignUpScreen with your actual sign-up screen widget
      ),
    );
  } catch (e) {
    print('Error signing out: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final selectedOption = await showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(0, 56, 0, 0), // Adjust the position as needed
                  items: [
                    PopupMenuItem<String>(
                      value: 'posts',
                      child: Row(
                        children: [
                          Icon(Icons.home, color: Colors.deepPurple,), // Home icon
                          const SizedBox(width: 8),
                          Text('Posts'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'fanning',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.deepPurple,), // Favorite icon
                          const SizedBox(width: 8),
                          Text('Fanning'),
                        ],
                      ),
                    ),
                  ],
                );

                if (selectedOption == 'posts') {
                  // Handle the 'posts' option click
                  // You can navigate to the posts page or perform any desired action
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisibleScreen(initialIndex: 0, userProfileImageUrl: 'userProfileImageUrl',),
                    ),
                  );
                } else if (selectedOption == 'fanning') {
                  // Handle the 'fanning' option click
                  // You can navigate to the fanning page or perform any desired action
                                                      _fetchUserData();

                }
              },
              child: const Text(
                '♥ ▼',
                style: TextStyle(color: Colors.deepPurple,),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
         actions: [
          IconButton(
  icon: Icon(Icons.notification_important_rounded, color: Colors.deepPurple),
  onPressed: () {
    // Navigate to the NotificationScreen when the notification icon is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(notifications: [], message: {},), // Pass the notifications list here
      ),
    );
  },
),
 TextButton(
  onPressed: () async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final otherUserId = '4d7PJvVf6RZCKxd0jxaa1TRgFLF2';

   
    // Navigate to the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: otherUserId),
      ),
    );
  },
  child: Column(
    children: [
      Text(
        'chat',
        style: TextStyle(color: Colors.deepPurple),
      ),
      Text(
        'admin',
        style: TextStyle(color: Colors.deepPurple),
      ),
    ],
  ),
),

PopupMenuButton<String>(
  onSelected: (value) async {
    // Handle the selected option
    if (value == 'forum') {
      // Handle forum option    
    
    } else if (value == 'sign out') {
      // Handle logout option
            await _signOut();
    } else if (value == 'admin_dashboard') {
     // Handle admin dashboard option
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem<String>(
                      value: 'forum',
                      child: Row(
                        children: [
                          Icon(
                            Icons.group,
                            color: Colors.deepPurple, // Deep purple color for the icon
                          ),
                          const SizedBox(width: 8),
                          Text('forum'),
                        ],
                      ),
                    ),
      PopupMenuItem<String>(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.deepPurple, // Deep purple color for the icon
                          ),
                          const SizedBox(width: 8),
                          Text('admin'),
                        ],
                      ),
                    ),
     PopupMenuItem<String>(
                      value: 'sign out',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.deepPurple, // Deep purple color for the icon
                          ),
                          const SizedBox(width: 8),
                          Text('sign out'),
                        ],
                      ),
                    ),
  ],
  icon: Icon(Icons.more_outlined, color: Colors.deepPurple),
),
  ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildAgeFilterDropdown(),
                buildSportFilterDropdown(),
                buildLevelFilterDropdown(),
                buildCountryFilterDropdown(),
                buildRoleFilterDropdown(),
                buildAthleteGenderFilterDropdown(),

              ],
            ),
          ),
          Expanded(
            child: usersList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : followingUserIds.isEmpty
                    ? Center(child: Text('You are not following any user.'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('posts').where('uid', whereIn: followingUserIds).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final posts = snapshot.data!.docs;

                          final filteredPosts = posts.where((post) {
                            final postData = post.data() as Map<String, dynamic>;
                            final user = usersList.firstWhere(
                              (user) => user.userId == postData['uid'],
                              orElse: () => User(
                                profileImageUrl: '',
                                username: 'Unknown',
                                country: 'Unknown',
                                age: '',
                                userId: postData['uid'],
                              ),
                            );

                            
                      if (filterAge != null && filterAge != 'Default') {
  final ageRange = filterAge!.split(' - ');
  if (ageRange.length == 2) {
    final ageLowerLimit = int.tryParse(ageRange[0]);
    final ageUpperLimit = int.tryParse(ageRange[1]);
    if (ageLowerLimit != null && ageUpperLimit != null) {
      final userAge = int.parse(user.age);
      if (userAge >= ageLowerLimit && userAge <= ageUpperLimit) {
        return true;
      }
    }
  } else if (ageRange.length == 3) {
    final ageLowerLimit = int.tryParse(ageRange[0]);
    if (ageLowerLimit != null) {
      final userAge = int.parse(user.age);
      if (userAge >= ageLowerLimit) {
        return true;
      }
    }
  }
  return false;
}

                            return (filterAge == null || user.age == filterAge) &&
                                (filterLevel == null || postData['level'] == filterLevel) &&
                                (filterSport == null || postData['sport'] == filterSport) &&
                                (filterCountry == null || user.country == filterCountry) &&
                                (filterRole == null || postData['role'] == filterRole) &&
                                (filterAthleteGender == null || postData['athletegender'] == filterAthleteGender); 

                          }).toList();

                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index].data() as Map<String, dynamic>;
                              final postId = filteredPosts[index].id;

                              if (deletedPostIds.contains(postId)) {
                                return SizedBox();
                              }

                              final user = usersList.firstWhere(
                                (user) => user.userId == post['uid'],
                                orElse: () => User(
                                  profileImageUrl: '',
                                  username: 'Unknown',
                                  country: 'Unknown',
                                  age: '',
                                  userId: post['uid'],
                                ),
                              );

                              final level = post['level'] ?? '';
                              final role = post['role'] ?? '';
                              final sport = post['sport'] ?? '';
                              final caption = post['caption'] ?? '';
                              final videoUrl = post['videoUrl'] ?? '';
                              final timestampStr = post['timestamp'] as String;
                              final athletegender = post['athletegender'] ?? '';

                              final chewieController = getChewieController(videoUrl);

                              final timestampMillis = int.tryParse(timestampStr) ?? 0;
                              final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
                              final formattedTimestamp = DateFormat.yMMMMd().add_jm().format(timestamp);

                              final isLikedByCurrentUser = post['likes'] != null && post['likes'][currentUserId] == true;

                              return Card(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(user.profileImageUrl),
                                      ),
                                      title: Text(user.username),
                                      onTap: () {
                                        if (user.userId == FirebaseAuth.instance.currentUser?.uid) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MyProfileScreen(userProfileImageUrl: '',),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => UserProfileScreen(userId: user.userId),
                                            ),
                                          );
                                        }
                                      },
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text('${user.country}, $athletegender, ${user.age}'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text('Sport: $sport', style: const TextStyle(fontSize: 12)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text('Role: $role', style: const TextStyle(fontSize: 12)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text('Level: $level', style: const TextStyle(fontSize: 12)),
                                          ),
                                           Text(formattedTimestamp),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(caption),
                                    ),
                                    AspectRatio(
                                      aspectRatio: 10 / 16,
                                      child: Chewie(
                                        controller: chewieController,
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final likesCount = post['likesCount'] ?? 0;

                                        return Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    _toggleLike(postId, isLikedByCurrentUser);
                                                  },
                                                  icon: Icon(
                                                    isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                                                    color: isLikedByCurrentUser ? Colors.deepPurpleAccent : null,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => CommentScreen(
                                                          postId: postId,
                                                          currentUsername: user.username,
                                                          profileImageUrl: user.profileImageUrl,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.comment),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    final String textToShare = 'Check out this post: $caption\n\nVideo: $videoUrl';

                                                    await FlutterShare.share(
                                                      title: 'Shared Post',
                                                      text: textToShare,
                                                      chooserTitle: 'Share',
                                                    );
                                                  },
                                                  icon: const Icon(Icons.share),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    if (!deletedPostIds.contains(postId)) {
                                                      _deletePost(postId, context);
                                                    }
                                                  },
                                                  icon: Icon(Icons.delete),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '$likesCount',
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Likes',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                                FutureBuilder<QuerySnapshot>(
                                                  future: _firestore.collection('posts').doc(postId).collection('comments').get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                                                      return const SizedBox();
                                                    }

                                                    final commentsCount = snapshot.data!.docs.length;

                                                    return Row(
                                                      children: [
                                                        Text(
                                                          '$commentsCount',
                                                          style: const TextStyle(fontSize: 16),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Text(
                                                          'Comments',
                                                          style: TextStyle(fontSize: 12),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Perform operations based on the selected index
          switch (index) {
            case 0:
              // Navigate to HomeScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VisibleScreen(initialIndex: 0, userProfileImageUrl: '',),
                ),
              );
              break;
            case 1:
              // Navigate to SearchScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VisibleScreen(initialIndex: 1, userProfileImageUrl: '',),
                ),
              );
              break;
            case 2:
              // Navigate to AddPostScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                                    builder: (context) => VisibleScreen(initialIndex: 2, userProfileImageUrl: '',),

                ),
              );
              break;
            case 3:
              // Navigate to ChatListScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                                    builder: (context) => VisibleScreen(initialIndex: 3, userProfileImageUrl: '',),

                ),
              );
              break;
            case 4:
              // Navigate to MyProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                                    builder: (context) => VisibleScreen(initialIndex: 4, userProfileImageUrl: '',),

                ),
              );
              break;
          }
        },
      ),
    );
  }



  ChewieController getChewieController(String videoUrl) {
    if (!chewieControllers.containsKey(videoUrl) || chewieControllers[videoUrl] == null) {
      final videoPlayerController = VideoPlayerController.network(videoUrl);
      final chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        aspectRatio: 10 / 16,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        autoInitialize: true,
      );

      chewieController.videoPlayerController.addListener(() {
        if (chewieController.videoPlayerController.value.isPlaying) {
          print('Video started playing');
        }
      });

      chewieControllers[videoUrl] = chewieController;
    }
    return chewieControllers[videoUrl]!;
  }

  
  List<String> ageRanges = [
    '7 - 9',
    '10 - 13',
    '14 - 17',
    '18 - 20',
    '21 - 23',
    '24 - 27',
    '28 - 30',
    '31 - 32',
    '33 - 35',
    '36 - 39',
    '40 - 45',
    '46 - 50',
    '51 and above',
  ]; // Add your desired age range options here

  Widget buildAgeFilterDropdown() {
    return DropdownButton<String>(
      value: filterAge,
      onChanged: (String? newValue) {
        setState(() {
          filterAge = newValue == 'Default' ? null : newValue;
        });
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Default',
          child: Text('Default'),
        ),
        ...ageRanges.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ],
      hint: Text('Age Range'),
    );
  }

  // Repeat the same pattern for other filter dropdowns

  Widget buildSportFilterDropdown() {
     final sports = ['Football/Soccer', 'Basketball', 'Tennis', 'Rugby', 'Cricket', 'Volleyball', 'American Football/Gridiron', 'Futsal/7 or 5 a side'
    'Athletics', 'Mixed Martial Arts','Boxing', 'Baseball', 'Field Hockey','Ice Hockey', 'Gymnastics', 'Swimming', 'Wrestling', 'Kickboxing', 'Table Tennis','Golf',
     'Snooker', 'Handball','Weight Lifting'];
    return DropdownButton<String>(
      value: filterSport,
      onChanged: (String? newValue) {
        setState(() {
          filterSport = newValue == 'Default' ? null : newValue;
        });
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Default',
          child: Text('Default'),
        ),
        ...sports.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ],
      hint: Text('Sport'),
    );
  }

  // Repeat the same pattern for other filter dropdowns

  Widget buildCountryFilterDropdown() {
    final countries = ['Afghanistan','Albania','Algeria','American Samoa','Andorra','Angola','Anguilla','Antigua and Barbuda','Argentina',
    'Armenia','Aruba','Australia','Austria','Azerbaijan','Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bermuda',
    'Bhutan','Bolivia','Bosnia and Herzegovina','Botswana','Brazil','Brunei Darussalam','Bulgaria','Burkina Faso','Burundi','Cambodia','Cameroon','Canada',
    'Cape Verde','Cayman Islands','Central African Republic','Chad','Chile','China','Christmas Island','Cocos Islands','Colombia','Comoros',
    'Democratic Republic of Congo','Republic of Congo','Cook Islands','Costa Rica','Croatia','Cuba','Cyprus','Czech Republic','Denmark','Djibouti',
    'Dominica','Dominican Republic','East Timor','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia','Ethiopia','Falkland Islands',
    'Faroe Islands','Fiji','Finland','France','French Guiana','French Polynesia','French Southern Territories','Gabon','Gambia','Georgia','Germany','Ghana',
    'Gibraltar','Greece','Greenland','Grenada','Guadeloupe','Guam','Guatemala','Guinea','Guinea-Bissau','Guyana','Haiti','Holy See','Honduras','Hong Kong',
    'Hungary','Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Ivory Coast','Jamaica','Japan','Jordan','Kazakhstan','Kenya',
    'Kiribati','North Korea','South Korea','Kosovo','Kuwait','Kyrgyzstan','Lao','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein','Lithuania','Luxembourg',
    'Macau','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Martinique','Mauritania','Mauritus','Mayotte','Mexico','Micronesia',
    'Moldova','Monaco','Mongolia','Montenegro','Montserrat','Morrocco','Mozambique','Myanmar','Namibia','Nauru','Nepal','Netherlands',
    'Netherlands Antilles','New Caledonia','New Zealand','Nicaragua','Niger','Nigeria','Niue','North Macedonia','Northern Mariana Islands','Norway','Oman'
    'Pakistan','Palau','Palestine','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Pitcairn Island','Poland','Portugal','Puerto Rico','Qatar'
    'Reunion Island','Romania','Russia','Rwanda','Saint Kitts and Nevis','Saint Lucia','Saint Vincent and the Grenadines','Samoa','San Marino',
    'Sao Tome and Principe','Saudi Arabia','Senegal','Serbia','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands','Somalia',
    'South Africa','South Sudan','Spain','Sri Lanka','Sudan','Suriname','Swaziland','Syria','Taiwan','Tajikistan','Tanzania','Thailand','Tibet','Timor-Leste',
    'Togo','Tokelau','Tonga','Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Turks and Caicos Islands','Tuvalu','Uganda','Ukraine',
    'United Arab Emirates','United Kingdom','United States','Uruguay','Uzbekistan','Vanautu','Vatican City State','Venezuela','Vietnam',
    'Virgin Islands','Wallis and Futuna Islands','Western Sahara','Yemen','Zambia','Zimbabwe'];
    return DropdownButton<String>(
      value: filterCountry,
      onChanged: (String? newValue) {
        setState(() {
          filterCountry = newValue == 'Default' ? null : newValue;
        });
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Default',
          child: Text('Default'),
        ),
        ...countries.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ],
      hint: Text('Regions'),
    );
  }

  // Repeat the same pattern for other filter dropdowns

  Widget buildLevelFilterDropdown() {
      final levels = [ 'Top Division Professional', 'League Professional/Second Division', 'League Professional/Third Division', 'League Professional/Fourth Division',
     'Semi Professional/Fifth and Sixth Division', 'Semi Professional/Lower Leagues', 'Grassroot/Academy','Professional(Individual Sports)',
      'Semi Professional(Individual Sports)', 'Amateur(Individual Sports)'];
    return DropdownButton<String>(
      value: filterLevel,
      onChanged: (String? newValue) {
        setState(() {
          filterLevel = newValue == 'Default' ? null : newValue;
        });
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Default',
          child: Text('Default'),
        ),
        ...levels.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ],
      hint: Text('Level'),
    );
  }

    Widget buildAthleteGenderFilterDropdown() {
    final athletegenders = [ 'Male','Female',];
    return DropdownButton<String>(
      value: filterAthleteGender,
      onChanged: (String? newValue) {
        setState(() {
          filterAthleteGender = newValue == 'Default' ? null : newValue;
        });
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Default',
          child: Text('Default'),
        ),
        ...athletegenders.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ],
      hint: Text('Athlete Gender'),
    );
  }
   // Repeat the same pattern for other filter dropdowns

  Widget buildRoleFilterDropdown() {
      final roles = ['Coach/Manager','Goalkeeper(Football/Soccer)', 'Central Defender(Football/Soccer)','Right Wing Back(Football/Soccer)', 'Left Wing Back(Football/Soccer)',
    'Defensive Midfielder(Football/Soccer)','Central Midfielder(Football/Soccer)','Attacking Midfielder(Football/Soccer)', 'Wing Forward(Football/Soccer)'
    'Striker(Football/Soccer)', 'Point Guard(Basketball)', 'Shooting Guard(Basketball)','Center(Basketball)','Small Forward(Basketball)', 'Power Forward(Basketball)',
     'Tennis Player(Tennis)', 'Tight Head Prop(Rugby)','Hooker(Rugby)', 'Loose Head Prop(Rugby)', 'Second Row(Rugby)', 'Blink Side Flanker(Rugby)',
      'Open Side Flanker(Rugby)','Number 8(Rugby)', 'Scrum Half(Rugby)', 'Fly Half(Rugby)', 'Left Wing(Rugby)', 'Inside Center(Rugby)', 'Outside Center(Rugby)',
       'Right Wing(Rugby)','Full Back(Rugby)', 'Wicketkeeper(Cricket)','Slip(Cricket)', 'Gully(Cricket)','Point(Cricket)','Cover(Cricket)', 'Third Man(Cricket)',
        'Fine Leg(Cricket)','Mid Wicket(Cricket)', 'Mid Off(Cricket)', 'Square Leg(Cricket)', 'Captain(Cricket)', 'Outside Hitter(Volleyball)', 'Opposite(Volleyball)',
         'Setter(Volleyball)', 'Middle Blocker(Volleyball)', 'Libero(Volleyball)', 'Defensive Specialist(Volleyball)', 'Serving Specialist(Volleyball)',
          'Center(American Football/Gridiron)', 'Offensive Guard(American Football/Gridiron)', 'Offensive Tackle(American Football/Gridiron)',
           'Quarterback(American Football/Gridiron)', 'Runningback(American Football/Gridiron)','Wide Receiver(American Football/Gridiron)','Tight End(American Football/Gridiron)',
           'Defensive Tackle(American Football/Gridiron)', 'Defensive End(American Football/Gridiron)', 'Linebacker(American Football/Gridiron)',
            'Middle Linebacker(American Football/Gridiron)', 'Outside Linebacker(American Football/Gridiron)', 'Cornerback(American Football/Gridiron)',
             'Safety(American Football/Gridiron)', 'Nickelback and Dimeback(American Football/Gridiron)', 'Kicker(American Football/Gridiron)',
             'Kickoff Specialist(American Football/Gridiron)', 'Punter(American Football/Gridiron)', 'Holder(American Football/Gridiron)','Long Snapper(American Football/Gridiron)',
             'Returner(American Football/Gridiron)','Upback(American Football/Gridiron)','Gunner(American Football/Gridiron)', 'Jammer(American Football/Gridiron)',
             'Goalkeeper(Futsal or Beach Soccer)', 'Defender(Futsal or Beach Soccer)', 'Winger(Futsal or Beach Soccer)', 'Forward(Futsal or Beach Soccer)', '100m Runner(Athletics)',
              '200m Runner(Athletics)', '400m Runner(Athletics)','800m Runner(Athletics)', '1500m Runner(Athletics)','Marathon Runner(Athletics)', 'Relay Runner(Athletics)',
              'Hurdle Runner(Athletics)', 'Long Jump(Athletics)', 'Triple Jump(Athletics)', 'High Jump(Athletics)', 'Pole Vault(Athletics)', 'Shot Put(Athletics)',
             'Discus Throw(Athletics)','Javelin Throw(Athletics)','Mixed Martial Artist(Mixed Martial Arts)','Boxer(Boxing)','Pitcher(Baseball)', 'Catcher(Baseball)',
            'First Baseman(Baseball)', 'Second Baseman(Baseball)','Third Baseman(Baseball)','Shortstop(Baseball)','Left Fielder(Baseball)','Right Fielder(Baseball)',
          'Center Fielder(Baseball)','Middle Infielder(Baseball)','Corner Infielder(Baseball)','Batter(Baseball)','Goalkeeper(Field Hockey)','Defender(Field Hockey)',
           'Sweeper(Field Hockey)','Midfielder(Field Hockey)','Attacker(Field Hockey)','Goalie(Ice Hockey)','Defenseman(Ice Hockey)','Wing(Ice Hockey)','Center(Ice Hockey)',
          'Gymnast(Gymnastics)','Swimmer(Swimming)','Wrestler(Wrestling)', 'Kickboxer(Kickboxing)','Table Tennis Player(Table Tennis)','Golfer(Golf)','Snooker Player(Snooker)',
         'Goalkeeper(Handball)','Left Back(Handball)','Right Back(Handball)','Center Back(Handball)', 'Center Forward(Handball)','Left Winger(Handball)', 'Right Winger(Handball)',
         'Weight Lifter(Weight Lifting)', 'Referee',];
    return DropdownButton<String>(
      value: filterRole,
      onChanged: (String? newValue) {
        setState(() {
          filterRole = newValue == 'Default' ? null : newValue;
        });
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Default',
          child: Text('Default'),
        ),
        ...roles.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ],
      hint: Text('Role'),
    );
  }


  Future<void> _toggleLike(String postId, bool isLiked) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      await postRef.collection('likes').doc(currentUserId).set({
        'isLiked': !isLiked,
      });

      final likesSnapshot = await postRef.collection('likes').get();
      final likesMap = likesSnapshot.docs.fold<Map<String, dynamic>>({}, (map, doc) {
        map[doc.id] = doc['isLiked'];
        return map;
      });
      await postRef.update({
        'likes': likesMap,
      });

      final likesCount = likesSnapshot.docs.where((doc) => doc['isLiked'] == true).length;
      await postRef.update({
        'likesCount': likesCount,
      });
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _deletePost(String postId, BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

      try {
        final postSnapshot = await postRef.get();
        final postUserId = postSnapshot.data()?['uid'] as String?;
        if (postSnapshot.exists && postUserId != null) {
          if (postUserId == currentUser.uid) {
            await postRef.delete();
            await postRef.collection('comments').get().then((snapshot) {
              for (final doc in snapshot.docs) {
                doc.reference.delete();
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Post deleted successfully')),
            );

            deletedPostIds.add(postId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You are not authorized to delete this post')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Post does not exist')),
          );
        }
      } catch (e) {
        print('Error deleting post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while deleting the post')),
        );
      }
    }
  }

  void _scrollListener() {
    final List<ChewieController> controllerValues = chewieControllers.values.toList();
    for (final controller in controllerValues) {
      if (controller.videoPlayerController.value.isPlaying) {
        controller.pause();
      }
    }
  }
}
