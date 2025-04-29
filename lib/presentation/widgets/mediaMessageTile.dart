import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../../core/shared/constants.dart';

class MediaMessageTile extends StatelessWidget {
  final String mediaUrl;
  final bool sentByMe;
  final String mediaType;
  final String sender;
  final String time;

  const MediaMessageTile({
    super.key,
    required this.mediaUrl,
    required this.sentByMe,
    required this.mediaType,
    required this.sender,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchMediaDetails(mediaUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _messageContainer(child: const CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _messageContainer(child: const Icon(Icons.error, color: Colors.red));
          }

          final url = 'https://media.bishalpantha.com.np${snapshot.data!['message']}';

          return _messageContainer(
            child: Column(
              crossAxisAlignment: sentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (sender.isNotEmpty) _senderName(),
                mediaType == 'video' ? VideoPlayerWidget(url: url) : _mediaImage(url),
                _timestamp(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _messageContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sentByMe ? Constants().primaryColor : Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _senderName() => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      sender,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
    ),
  );

  Widget _mediaImage(String url) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      url,
      width: 250,
      height: 250,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loading) {
        if (loading == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
    ),
  );

  Widget _timestamp() => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      time,
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    ),
  );

  Future<Map<String, dynamic>> _fetchMediaDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch media');
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    print('Playing video from: ${widget.url}');
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _controller.play());
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 48);
    }
    return _controller.value.isInitialized
        ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
        : const Center(child: CircularProgressIndicator());
  }
}
