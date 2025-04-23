import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/shared/constants.dart';

class MediaMessageTile extends StatelessWidget {
  final String message; // GET endpoint URL for media
  final bool sentByMe;
  final String mediaType;
  final String sender;
  final String time;

  const MediaMessageTile({
    super.key,
    required this.message,
    required this.sentByMe,
    required this.mediaType,
    required this.sender,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchMediaDetails(message),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildMessageContainer(
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _buildMessageContainer(
                  child: const Icon(Icons.error, color: Colors.red),
                );
              }

              final mediaUrl = 'http://localhost:8000${snapshot.data!['message']}';

              return _buildMessageContainer(
                child: Column(
                  crossAxisAlignment: sentByMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name (if needed)
                    if (sender.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          sender,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),

                    // Media content (image or video)
                    mediaType == 'video'
                        ? _buildVideoPlayer(mediaUrl)
                        : _buildImage(mediaUrl),

                    // Time stamp
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sentByMe ? Constants().primaryColor : Colors.grey[700],
        borderRadius: sentByMe
            ? const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        )
            : const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: child,
    );
  }

  Widget _buildVideoPlayer(String mediaUrl) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 50, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              'Video Message',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String mediaUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        mediaUrl,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey[800],
            width: 250,
            height: 250,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            width: 250,
            height: 250,
            child: const Icon(Icons.broken_image, color: Colors.red),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchMediaDetails(String mediaUrl) async {
    final response = await http.get(Uri.parse(mediaUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load media details');
    }
  }
}
