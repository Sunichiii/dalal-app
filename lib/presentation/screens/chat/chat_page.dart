import 'dart:convert';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/services/database_service.dart';
import '../../widgets/message_tile.dart';
import '../../widgets/widgets.dart';
import '../group info/group_info.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_page_widgets.dart';
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
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FocusNode messageFocusNode = FocusNode();
  bool isEmojiVisible = false;
  String mediaPreview = '';
  bool isUploading = false;
  double uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<ChatBloc>(context).add(LoadChats(groupId: widget.groupId));
  }

  Future<void> _pickMedia() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultipleMedia(
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          isUploading = true;
          uploadProgress = 0.0;
          mediaPreview = pickedFiles.first.path;
        });

        for (final pickedFile in pickedFiles) {
          try {
            final File mediaFile = File(pickedFile.path);
            print('Starting upload for: ${pickedFile.name}');

            // Upload media and get mediaId
            final mediaId = await _uploadMediaToBackend(mediaFile);
            print('Received mediaId: $mediaId');

            // Construct GET endpoint URL
            final getEndpointUrl = 'http://192.168.1.69:8000/api/media/$mediaId';
            print('Using GET endpoint: $getEndpointUrl');

            // Store in Firestore
            await DatabaseService(
              uid: FirebaseAuth.instance.currentUser?.uid,
            ).sendMediaMessage(
              widget.groupId,
              getEndpointUrl,
              widget.userName,
              pickedFile.path.endsWith('.mp4') ? 'video' : 'image',
            );

            print('Successfully uploaded: ${pickedFile.name}');
          } catch (e) {
            print('Error uploading ${pickedFile.name}: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ${pickedFile.name}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        setState(() {
          isUploading = false;
          mediaPreview = '';
        });
      }
    } catch (e) {
      print('Error picking media: $e');
      setState(() {
        isUploading = false;
        mediaPreview = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting files: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _uploadMediaToBackend(File mediaFile) async {
    try {
      const backendUrl = 'http://192.168.1.69:8000/api/uploadmedia';
      print('Uploading to: $backendUrl');

      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          mediaFile.path,
          contentType: mediaFile.path.endsWith('.mp4')
              ? MediaType('video', 'mp4')
              : MediaType('image', 'jpeg'),
        ),
      );

      request.fields.addAll({
        'sender': widget.userName,
        'groupId': widget.groupId,
        'mediaType': mediaFile.path.endsWith('.mp4') ? 'video' : 'image',
      });

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData.body);
        final mediaId = jsonResponse['mediaId'];
        if (mediaId == null) throw Exception('No mediaId received');
        return mediaId;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${responseData.body}');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchMediaDetails(String getEndpointUrl) async {
    try {
      print('Fetching media details from: $getEndpointUrl');
      final response = await http.get(Uri.parse(getEndpointUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch media details');
      }
    } catch (e) {
      print('Error fetching media details: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      appBar: AppBar(
        backgroundColor: Constants().primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 4,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              String fetchedAdmin = await DatabaseService().getGroupAdmin(
                widget.groupId,
              );
              nextScreen(
                context,
                GroupInfo(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  adminName: fetchedAdmin,
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildChatMessages()),
              if (isEmojiVisible)
                EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    messageController.text += emoji.emoji;
                    messageFocusNode.requestFocus();
                  },
                ),
              _buildMessageInput(),
            ],
          ),
          if (isUploading) _buildUploadProgressIndicator(),
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                itemCount: snapshot.data.docs.length,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
                itemBuilder: (context, index) {
                  final messageData = snapshot.data.docs[index];
                  final sender = messageData['sender'];
                  final uid = sender.contains('_') ? sender.split('_')[0] : sender;
                  final displayName = state.anonMap[uid] ?? "Admin";
                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  final sentByMe = sender.startsWith(currentUserId);

                  final messageDateTime = DateTime.fromMillisecondsSinceEpoch(
                      messageData['time']);
                  final formattedTime = DateFormat('hh:mm a').format(messageDateTime);
                  final messageType = messageData['type'] ?? 'text';
                  final message = messageData['message'];

                  if (messageType == 'media') {
                    return _buildMediaMessage(
                      message,
                      sentByMe,
                      displayName,
                      formattedTime,
                    );
                  } else {
                    return MessageTile(
                      message: message,
                      sender: displayName,
                      sentByMe: sentByMe,
                      time: formattedTime,
                      messageType: messageType,
                    );
                  }
                },
              );
            },
          );
        } else if (state is ChatError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildMediaMessage(
      String getEndpointUrl,
      bool sentByMe,
      String senderName,
      String time,
      ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMediaDetails(getEndpointUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            mainAxisAlignment:
            sentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Row(
            mainAxisAlignment:
            sentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: const [
              Icon(Icons.error, color: Colors.red),
            ],
          );
        }

        final mediaPath = snapshot.data!['message'];
        final mediaUrl = 'http://192.168.1.69:8000$mediaPath';
        final isVideo = mediaPath.endsWith('.mp4');

        return Row(
          mainAxisAlignment:
          sentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: isVideo
                  ? VideoPlayerWidget(url: mediaUrl)
                  : Image.network(
                mediaUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image);
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Constants().primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: isUploading ? null : _pickMedia,
            color: Constants().accentColor,
            tooltip: 'Attach media',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions),
            onPressed: () {
              setState(() {
                isEmojiVisible = !isEmojiVisible;
                if (isEmojiVisible) {
                  FocusScope.of(context).unfocus();
                } else {
                  messageFocusNode.requestFocus();
                }
              });
            },
            color: Constants().accentColor,
            tooltip: 'Emoji',
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      focusNode: messageFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.white54),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                      ),
                      onTap: () {
                        if (isEmojiVisible) {
                          setState(() => isEmojiVisible = false);
                        }
                      },
                    ),
                  ),
                  if (mediaPreview.isNotEmpty && !isUploading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => mediaPreview = ''),
                        child: Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(mediaPreview)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -5,
                              right: -5,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.red,
                                onPressed: () => setState(() => mediaPreview = ''),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              if (messageController.text.isNotEmpty && !isUploading) {
                BlocProvider.of<ChatBloc>(context).add(
                  SendMessage(
                    groupId: widget.groupId,
                    userName: widget.userName,
                    message: messageController.text,
                  ),
                );
                messageController.clear();
                messageFocusNode.requestFocus();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: messageController.text.isNotEmpty && !isUploading
                    ? Constants().accentColor
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressIndicator() {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Constants().accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading... ${(uploadProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}