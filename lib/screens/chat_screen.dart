import 'dart:io';
import 'package:athlosight/screens/full_screen_image.dart';
import 'package:athlosight/screens/full_screen_video.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String userId; 


  const ChatScreen({super.key, required this.userId, });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ImagePicker _videoPicker = ImagePicker();

  @override
void initState() {
  super.initState();
  _markChatAsRead();
}

// Define the _markChatAsRead method to mark the chat as read
  void _markChatAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = _getChatId();
 // Update the unreadCount to 0 for the current user's chat with the recipient
  final currentUserChatRef = FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('chats')
      .doc(widget.userId);
  currentUserChatRef.update({'unreadCount': 0});
    // Update the unreadCount to 0 to mark the chat as read
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({'unreadCount': 0});
  }



  void _openFullScreenImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => FullScreenImageDialog(imageUrl: imageUrl),
    );
  }

  void _openFullScreenVideoDialog(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => FullScreenVideoDialog(videoUrl: videoUrl),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final String formattedTime = DateFormat('MMM d, yyyy, HH:mm').format(dateTime);
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Chat'); // While loading, display a default text.
            }

            if (snapshot.hasData && snapshot.data != null) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;

              if (userData != null) {
                final username = userData['username'] as String?;
                final profileImageUrl = userData['profileImageUrl'] as String?;

                return Row(
                  children: [
                    if (profileImageUrl != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(profileImageUrl),
                      ),
                    if (profileImageUrl != null) const SizedBox(width: 10),
                    Text(username ?? 'User'), // If username is null, display 'User'.
                  ],
                );
              }
            }

            return const Text('Chat'); // If no data found, display a default text.
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId())
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>?;

                    if (message == null) {
                      // If message is null, return an empty widget or handle it accordingly.
                      return const SizedBox.shrink();
                    }

                    final senderId = message['senderId'] as String?;
                        final receiverId = message['receiverId'] as String?; // Add this line to get the receiverId
                    final messageText = message['message'] as String?;
                    final imageUrl = message['imageUrl'] as String?;
                    final videoUrl = message['videoUrl'] as String?;
                    final timestamp = message['timestamp'] as Timestamp?;

                   
    if (senderId == null || receiverId == null || (messageText == null && imageUrl == null && videoUrl == null)) {
      // If senderId, receiverId, or messageText or imageUrl or videoUrl is null, return an empty widget or handle it accordingly.
      return const SizedBox.shrink();
    }

                    final isCurrentUser = senderId == FirebaseAuth.instance.currentUser?.uid;                    

                    String statusText = '';
                    if (message.containsKey('status')) {
                      final status = message['status'] as String?;
                      if (status == 'sent') {
                        statusText = 'Sent';
                      } else if (status == 'delivered') {
                        statusText = 'Delivered';
                      } else if (status == 'read') {
                        statusText = 'Read';
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        if (imageUrl != null) {
                          _openFullScreenImageDialog(imageUrl);
                        } else if (videoUrl != null) {
                          _openFullScreenVideoDialog(videoUrl);
                        }
                      },
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            messageText != null ? Text(messageText) : const SizedBox.shrink(),
                            timestamp != null ? Text(
                              _formatTimestamp(timestamp),
                              style: const TextStyle(
                                color: Colors.deepPurple, // Set the color you want for the timestamp
                                fontSize: 12, // Set the desired font size for the timestamp
                              ),
                            ) : const SizedBox.shrink(),
                            Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.deepPurple, // Set the color you want for the status text
                                fontSize: 12, // Set the desired font size for the status text
                              ),
                            ),
                          ],
                        ),
                        leading: imageUrl != null ? SizedBox(
                          width: 56, // Set an appropriate width for the leading widget
                          child: Image.network(imageUrl),
                        ) : const SizedBox.shrink(),
                        trailing: videoUrl != null ? const Icon(Icons.video_library) : const SizedBox.shrink(),
                        // You can style the list tile differently based on whether it's sent by the current user or the other user.
                        // For example, you can change the background color for messages sent by the current user.
                        tileColor: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    maxLines: null, // Allow the text field to grow and display multiple lines
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.video_library),
                  onPressed: _pickVideo,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {                   
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChatId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '';

    final List<String> userIds = [currentUser.uid, widget.userId];
    userIds.sort(); // Sort the IDs to ensure consistency

    return userIds.join('_'); // Create a unique chat ID
  }

  void _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = _getChatId();
    final message = _messageController.text.trim();

    if (message.isEmpty) return;

    // Save the message to Firestore
    final messageData = {
      'message': message,
      'senderId': currentUser.uid,
        'receiverId': widget.userId, // Assuming widget.userId is the receiver's user ID
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent', // Initial status is "sent"
    };

    final messageRef = await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(messageData);

 // Increment the unreadCount for the recipient's chat document
  final recipientChatRef = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('chats').doc(currentUser.uid);
  recipientChatRef.update({'unreadCount': FieldValue.increment(1)});


    // Send FCM message to the recipient with the message ID and type
    final fcmTokenSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final fcmToken = fcmTokenSnapshot.data()?['fcmToken'] as String?;

    if (fcmToken != null) {
      const serverKey = 'AAAAXkK62jM:APA91bH-skqZ2rDRBso_SdHjyef4fsRJQtpFAntIBFM0Ey8-Hy4mzqcq7HgqEuRN0YfExug8KkhRjq0L6DvMM3qN4kr9IhF1BzgnufvuqDedL93aIC3sHPpe4ePfXEOcuXXsyDvfEnu-'; // Replace with your Firebase Server Key
      const url = 'https://fcm.googleapis.com/fcm/send';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      final body = {
        'to': fcmToken,
        'data': {
          'messageId': messageRef.id,
          'type': 'sent',
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('FCM message sent successfully.');
      } else {
        print('Failed to send FCM message. Status code: ${response.statusCode}');
      }
    }
    // Clear the text input after sending the message
    _messageController.clear();
  }

  Future<bool> _isExistingChat() async {
    final chatId = _getChatId();
    final snapshot = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    return snapshot.exists;
  }
  
void _saveChatToFirestore(String otherUserId, String otherUsername, String otherProfileImageUrl) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final currentUserData = {
    'userId': currentUser.uid,
    'username': currentUser.displayName ?? '',
    'profileImageUrl': currentUser.photoURL ?? '',
  };

  final otherUserData = {
    'userId': otherUserId,
    'username': otherUsername,
    'profileImageUrl': otherProfileImageUrl,
  };

  // Save the chat data for the current user
  FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('chats')
      .doc(otherUserId)
      .set(otherUserData);

  // Save the chat data for the other user
  FirebaseFirestore.instance
      .collection('users')
      .doc(otherUserId)
      .collection('chats')
      .doc(currentUser.uid)
      .set(currentUserData);
}

  void _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload the image to Firebase Storage
      final imageFile = File(pickedFile.path);
      final storageReference = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageReference.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Save the imageUrl to Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final chatId = _getChatId();

      // Save the imageUrl to Firestore
      await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
        'imageUrl': imageUrl,
        'senderId': currentUser.uid,
                'receiverId': widget.userId, // Assuming widget.userId is the receiver's user ID
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _pickVideo() async {
    final pickedFile = await _videoPicker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload the video to Firebase Storage
      final videoFile = File(pickedFile.path);
      final storageReference = FirebaseStorage.instance.ref().child('videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
      final uploadTask = storageReference.putFile(videoFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final videoUrl = await taskSnapshot.ref.getDownloadURL();

      // Save the videoUrl to Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final chatId = _getChatId();

      // Save the videoUrl to Firestore
      await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
        'videoUrl': videoUrl,
        'senderId': currentUser.uid,
                'receiverId': widget.userId, // Assuming widget.userId is the receiver's user ID
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}
