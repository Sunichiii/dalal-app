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
  String mediaType = '';

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

            final mediaUrl = await _uploadMediaToBackend(mediaFile);

            await DatabaseService(
              uid: FirebaseAuth.instance.currentUser?.uid,
            ).sendMediaMessage(
              widget.groupId,
              mediaUrl,
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

      // Track upload progress manually
      final response = await request.send();
      final contentLength = response.contentLength ?? 0;
      int bytesUploaded = 0;
      final chunks = <List<int>>[];

      // Process stream only once
      await response.stream.listen(
            (List<int> chunk) {
          bytesUploaded += chunk.length;
          chunks.add(chunk);
          setState(() {
            uploadProgress = bytesUploaded / contentLength;
          });
        },
        onError: (e) => throw Exception('Upload error: $e'),
        cancelOnError: true,
      ).asFuture();

      // Get response data from collected chunks
      final responseData = await http.Response.fromStream(
        http.StreamedResponse(
          Stream.value(chunks.expand((x) => x).toList()),
          response.statusCode,
          contentLength: contentLength,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData.body);
        final filePath = jsonResponse['filePath'];
        String fullUrl = filePath.startsWith('http')
            ? filePath
            : 'http://192.168.1.69:8000$filePath';
        print('File uploaded successfully. Path: $fullUrl');
        return fullUrl;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${responseData.body}');
      }
    } catch (e) {
      print('Upload error: $e');
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
              Expanded(child: chatMessages()),
              isEmojiVisible
                  ? EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  messageController.text += emoji.emoji;
                  messageFocusNode.requestFocus();
                },
              )
                  : Container(),
              messageInputField(),
            ],
          ),
          if (isUploading)
            Positioned(
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
            ),
        ],
      ),
    );
  }

  Widget chatMessages() {
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
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              });

              return ListView.builder(
                controller: _scrollController,
                itemCount: snapshot.data.docs.length,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
                itemBuilder: (context, index) {
                  var messageData = snapshot.data.docs[index];
                  String sender = messageData['sender'];
                  String uid =
                  sender.contains('_') ? sender.split('_')[0] : sender;
                  String displayName = state.anonMap[uid] ?? "Admin";
                  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  bool sentByMe = sender.startsWith(currentUserId);

                  DateTime messageDateTime =
                  DateTime.fromMillisecondsSinceEpoch(messageData['time']);
                  String formattedTime = DateFormat(
                    'hh:mm a',
                  ).format(messageDateTime);

                  String messageType = messageData['type'] ?? 'text';
                  String message = messageData['message'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (messageType == 'media')
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: message.contains('.mp4')
                              ? VideoPlayerWidget(url: message)
                              : Image.network(
                            message,
                            width: 250,
                            height: 250,
                            fit: BoxFit.cover,
                            loadingBuilder: (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress,
                                ) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 250,
                                height: 250,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress
                                        .expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                                ) {
                              return Container(
                                width: 250,
                                height: 250,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (messageType == 'text')
                        MessageTile(
                          message: message,
                          sender: displayName,
                          sentByMe: sentByMe,
                          time: formattedTime,
                          messageType: messageType,
                        ),
                    ],
                  );
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

  Widget messageInputField() {
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
                          setState(() {
                            isEmojiVisible = false;
                          });
                        }
                      },
                    ),
                  ),
                  if (mediaPreview.isNotEmpty && !isUploading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            mediaPreview = '';
                          });
                        },
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
                                onPressed: () {
                                  setState(() {
                                    mediaPreview = '';
                                  });
                                },
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
}
