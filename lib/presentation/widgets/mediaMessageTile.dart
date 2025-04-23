import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../screens/chat/bloc/chat_page_widgets.dart';

class MediaMessageTile extends StatelessWidget {
  final String message; // This is now the GET endpoint URL
  final bool sentByMe;
  final String mediaType;

  const MediaMessageTile({
    super.key,
    required this.message,
    required this.sentByMe,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMediaDetails(message),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Icon(Icons.error);
        }

        final mediaUrl = 'http://localhost:8000${snapshot.data!['message']}';

        return Align(
          alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: mediaType == 'video'
                ? VideoPlayerWidget(url: mediaUrl)
                : Image.network(
              mediaUrl,
              headers: {"Accept": "image/*"},
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            ),
          ),
        );
      },
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
