import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);
  
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  late File _videoFile;
  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();
    String? _selectedRole;
  String? _selectedLevel;
  String? _selectedSport;
  String? _selectedAthleteGender;

  final ImagePicker _picker = ImagePicker();
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _selectVideoFromGallery() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);

      setState(() {
        _videoFile = videoFile;
        _videoController = VideoPlayerController.file(_videoFile)
          ..initialize().then((_) {
            _videoController!.play();
            _videoController!.setLooping(true);
          });
      });
    }
  }

  Future<void> _recordVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);

      setState(() {
        _videoFile = videoFile;
        _videoController = VideoPlayerController.file(_videoFile)
          ..initialize().then((_) {
            _videoController!.play();
            _videoController!.setLooping(true);
          });
      });
    }
  }

  Future<void> _uploadPost() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    
  if (_selectedRole == null || _selectedLevel == null || _selectedSport == null || _selectedAthleteGender == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select position, level,sport and gender')),
    );
    return;
  }

    final uid = currentUser.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final postRef =
          _storage.ref().child('posts/$uid/$timestamp.mp4');
      final uploadTask = postRef.putFile(_videoFile);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final caption = _captionController.text.trim();
      await _firestore.collection('posts').add({
        'uid': uid,
        'videoUrl': downloadUrl,
        'timestamp': timestamp,
        'caption': caption,
        'role': _selectedRole,
      'level': _selectedLevel,
      'sport': _selectedSport,
      'athletegender': _selectedAthleteGender
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully')),
      );

      // Stop video playback and dispose the controller
      _videoController?.pause();
      _videoController?.dispose();

      // Clear the video file, controller, and caption text
      setState(() {
        _videoFile = File('');
        _videoController = null;
        _captionController.clear();
          _selectedRole = null;
      _selectedLevel = null;
      _selectedSport = null;
      _selectedAthleteGender = null;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload post: $error')),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        'Add Post',
        style: TextStyle(
          color: Colors.deepPurple, // Set the text color to deep purple
        ),
      ),
    ],
  ),
),
     
    );
  }
}