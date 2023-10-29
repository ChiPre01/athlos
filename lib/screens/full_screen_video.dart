import 'package:athlosight/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';

class FullScreenVideoDialog extends StatelessWidget {
  final String videoUrl;

  const FullScreenVideoDialog({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: AspectRatio(
          aspectRatio: 16 / 9, // Adjust the aspect ratio to fit your video dimensions
          child: VideoPlayerWidget(videoUrl: videoUrl),
        ),
      ),
    );
  }
}
