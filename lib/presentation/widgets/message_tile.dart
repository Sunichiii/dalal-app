import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';

class MessageTile extends StatelessWidget {
  final String message;
  final String sender;
  final bool sentByMe;
  final String time;
  final String messageType; // 'text', 'image', or 'video'

  const MessageTile({
    super.key,
    required this.message,
    required this.sender,
    required this.sentByMe,
    required this.time,
    required this.messageType,
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
          child: Column(
            crossAxisAlignment: sentByMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Sender name
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

              // Message content
              _buildMessageContent(),

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
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (messageType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message,
            width: 250,
            height: 250,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[800],
              width: 250,
              height: 250,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[800],
              width: 250,
              height: 250,
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        );
      case 'video':
        return Container(
          width: 250,
          height: 250,
          color: Colors.black,
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
      default: // text
        return Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        );
    }
  }
}