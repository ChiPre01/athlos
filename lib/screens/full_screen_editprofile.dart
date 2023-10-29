import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String profileImageUrl;

  const FullScreenImage({required this.profileImageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Screen Image'),
      ),
      body: Center(
        child: Hero(
          tag: 'profileImage',
          child: Image.network(profileImageUrl),
        ),
      ),
    );
  }
}
