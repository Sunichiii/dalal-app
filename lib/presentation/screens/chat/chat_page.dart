import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/media_upload_services.dart';
import '../../widgets/mediaMessageTile.dart';
import '../../widgets/message_tile.dart';
import '../group info/group_info.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userName;

  const ChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _isEmojiVisible = false;
  bool _isUploading = false;
  String _mediaPreview = '';

  @override
  void initState() {
    super.initState();
    BlocProvider.of<ChatBloc>(context).add(LoadChats(
      groupId: widget.groupId,
      message: '',
      userName: widget.userName,
    ));
  }

  Future<void> _pickAndUploadMedia() async {
    final pickedFiles = await _picker.pickMultipleMedia(imageQuality: 85);

    if (pickedFiles == null || pickedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    for (final picked in pickedFiles) {
      final file = File(picked.path);
      try {
        final mediaUrl = await MediaUploadService.uploadMedia(
          file: file,
          sender: widget.userName,
          groupId: widget.groupId,
        );

        await DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid).sendMediaMessage(
          widget.groupId,
          mediaUrl,
          widget.userName,
          file.path.endsWith('.mp4') ? 'video' : 'image',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() {
      _isUploading = false;
      _mediaPreview = '';
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _isUploading) return;

    BlocProvider.of<ChatBloc>(context).add(
      SendMessage(
        groupId: widget.groupId,
        userName: widget.userName,
        message: _messageController.text.trim(),
      ),
    );

    _messageController.clear();
    _messageFocusNode.requestFocus();
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
      if (_isEmojiVisible) {
        FocusScope.of(context).unfocus();
      } else {
        _messageFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      appBar: AppBar(
        backgroundColor: Constants().primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () async {
              final admin = await DatabaseService().getGroupAdmin(widget.groupId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfo(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    adminName: admin,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildChatMessages()),
              if (_isEmojiVisible) _buildEmojiPicker(),
              _buildMessageInput(),
            ],
          ),
          if (_isUploading) _buildUploadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ChatLoaded) {
          return StreamBuilder(
            stream: state.chats,
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data.docs[index];
                  final isMedia = data['type'] == 'media';
                  final senderId = data['sender'].split('_').first;
                  final displayName = state.anonMap[senderId] ?? "Admin";
                  final isSentByMe = senderId == FirebaseAuth.instance.currentUser?.uid;
                  final messageTime = DateFormat('hh:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(data['time']),
                  );

                  return isMedia
                      ? MediaMessageTile(
                    mediaUrl: data['message'],
                    sentByMe: isSentByMe,
                    mediaType: data['mediaType'],
                    sender: displayName,
                    time: messageTime,
                  )
                      : MessageTile(
                    message: data['message'],
                    sentByMe: isSentByMe,
                    sender: displayName,
                    time: messageTime,
                    messageType: 'text',
                  );
                },
              );
            },
          );
        } else if (state is ChatError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Constants().primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Constants().accentColor,
            onPressed: _isUploading ? null : _pickAndUploadMedia,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions),
            color: Constants().accentColor,
            onPressed: _toggleEmojiPicker,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextFormField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onTap: () {
                  if (_isEmojiVisible) setState(() => _isEmojiVisible = false);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_messageController.text.isNotEmpty && !_isUploading)
                    ? Constants().accentColor
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        _messageController.text += emoji.emoji;
        _messageFocusNode.requestFocus();
      },
    );
  }

  Widget _buildUploadingOverlay() {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            LinearProgressIndicator(),
            SizedBox(height: 8),
            Text('Uploading...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
