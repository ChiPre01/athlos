import 'package:flutter/material.dart';

class FullScreenImageProfile extends StatelessWidget {
  final String imageUrl;

  FullScreenImageProfile({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: 'fullscreen-image',
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
