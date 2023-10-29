import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String currentUsername;
  final String profileImageUrl;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.currentUsername,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();

  void _submitComment() {
    final String commentText = _commentController.text.trim();

    if (commentText.isNotEmpty) {
      // Get the user ID of the commenter
      final commenterId = FirebaseAuth.instance.currentUser!.uid;

      // Create a new comment document
      final comment = {
        'commenterId': commenterId,
        'commentText': commentText,
        'timestamp': Timestamp.now(),
      };

      // Add the comment to the 'comments' subcollection of the post
      FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add(comment)
          .then((value) {
        // Clear the comment text field after successful submission
        _commentController.clear();
      }).catchError((error) {
        // Handle the error if the comment submission fails
        print('Failed to submit comment: $error');
      });
    }
  }

  void _deleteComment(String commentId) {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .get()
        .then((commentDoc) {
      final commenterId = commentDoc.data()?['commenterId'];

      if (commenterId == currentUserUid) {
        commentDoc.reference.delete().then((value) {
          // Comment deletion successful
        }).catchError((error) {
          // Handle the error if comment deletion fails
          print('Failed to delete comment: $error');
        });
      } else {
        // User is not the owner of the comment, handle accordingly
        print('You can only delete your own comments.');
      }
    }).catchError((error) {
      // Handle the error if fetching the comment fails
      print('Failed to fetch comment: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment =
                        comments[index].data() as Map<String, dynamic>;

                    final commentId = comments[index].id;
                    final commenterId = comment['commenterId'] ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(commenterId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            !userSnapshot.hasData) {
                          return const SizedBox();
                        }

                        final commenterData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;

                        if (commenterData == null) {
                          return const SizedBox();
                        }

                        final commenterUsername =
                            commenterData['username'] ?? '';
                        final commenterProfileImageUrl =
                            commenterData['profileImageUrl'] ?? '';

                        final commentText = comment['commentText'] ?? '';
                        final timestamp = comment['timestamp'] as Timestamp;

                        final formattedTimestamp = DateFormat.yMMMMd()
                            .add_jm()
                            .format(timestamp.toDate());

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(commenterProfileImageUrl),
                          ),
                          title: Text(commenterUsername),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(commentText),
                              const SizedBox(height: 4.0),
                              Text(
                                formattedTimestamp,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: (commenterId ==
                                  FirebaseAuth.instance.currentUser!.uid)
                              ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteComment(commentId);
                                  },
                                )
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.profileImageUrl),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: null, // Set maxLines to allow multiple lines
                    textInputAction: TextInputAction.newline, // Display the enter key for line breaks
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
