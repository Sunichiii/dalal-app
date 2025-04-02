import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Import emoji picker package
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // For picking media (image/video)
  final ImagePicker _picker = ImagePicker();

  // Method to pick image or video
  Future<void> _pickMedia() async {
    try {
      // Pick either image or video
      XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      // If no image is selected, try to pick video
      pickedFile ??= await _picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile != null) {
        File mediaFile = File(pickedFile.path);

        // Send the picked media as message (image or video)
        await DatabaseService(
          uid: FirebaseAuth.instance.currentUser?.uid,
        ).sendMediaMessage(widget.groupId, mediaFile, widget.userName);
      }
    } catch (e) {
      print("Error picking media file: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    BlocProvider.of<ChatBloc>(context).add(LoadChats(groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      appBar: AppBar(
        backgroundColor: Constants().primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
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
      body: Column(
        children: [
          Expanded(child: chatMessages()), // Displays chat messages
          isEmojiVisible
              ? EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  messageController.text +=
                      emoji.emoji; // Add emoji to text input
                  messageFocusNode
                      .requestFocus(); // Ensure the focus is still on the input field
                },
              )
              : Container(), // Show emoji picker if visible
          messageInputField(), // Message input field
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
                  String displayName =
                      state.anonMap[uid] ??
                      "Anonymous"; // Display anonymous name
                  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  bool sentByMe = sender.startsWith(currentUserId);

                  DateTime messageDateTime =
                      DateTime.fromMillisecondsSinceEpoch(messageData['time']);
                  String formattedTime = DateFormat(
                    'hh:mm a',
                  ).format(messageDateTime);

                  // Safely access 'type' field, default to 'text' if missing
                  String messageType =
                      messageData['type'] ?? 'text'; // Default to 'text'
                  String message = messageData['message'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (messageType == 'media')
                        // Display media (image/video) if message is media
                        Image.network(message),
                      // For images
                      if (messageType == 'media' && message.contains('video'))
                        // For video messages, use a video player widget if necessary
                        VideoPlayerWidget(url: message),
                      // Custom video player widget
                      if (messageType == 'text')
                        // Display text message
                        MessageTile(
                          message: message,
                          sender: displayName,
                          sentByMe: sentByMe,
                          time: formattedTime,
                        ),
                    ],
                  );
                },
              );
            },
          );
        } else if (state is ChatError) {
          return Center(
            child: Text(state.message, style: TextStyle(color: Colors.red)),
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
          // Expanded Text Input Field (on the right)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextFormField(
                controller: messageController,
                focusNode: messageFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          // Attach Media Button (camera icon)
          IconButton(
            icon: const Icon(Icons.attach_file_sharp),
            onPressed: _pickMedia, // Your media picking function
            color: Constants().accentColor,
          ),

          // Emoji Button
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
            color:  Constants().accentColor,
          ),

          const SizedBox(width: 10),

          // Send Button
          GestureDetector(
            onTap: () {
              if (messageController.text.isNotEmpty) {
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    messageController.text.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_sharp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
