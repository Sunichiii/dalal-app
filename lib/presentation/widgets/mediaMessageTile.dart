import 'package:flutter/material.dart';

import '../screens/chat/bloc/chat_page_widgets.dart';

class MediaMessageTile extends StatelessWidget {
  final String message; // media URL (image or video URL)
  final bool sentByMe; // Check if message is sent by current user

  const MediaMessageTile({
    super.key,
    required this.message,
    required this.sentByMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sentByMe ? Colors.blueAccent : Colors.grey[700],
          borderRadius: sentByMe
              ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          )
              : const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          sentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            message.contains('.mp4') // Check if it's a video URL
                ? VideoPlayerWidget(url: message)
                : Image.network(
              message, // For images
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
