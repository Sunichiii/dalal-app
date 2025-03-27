import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/services/database_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/message_tile.dart';
import '../../widgets/widgets.dart';
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
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FocusNode messageFocusNode = FocusNode();
  String admin = "";

  @override
  void initState() {
    super.initState();
    BlocProvider.of<ChatBloc>(context).add(LoadChats(groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        elevation: 4,
        backgroundColor: theme.primaryColor,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async{
              String fetchedAdmin = await DatabaseService().getGroupAdmin(widget.groupId); //changes made here
              nextScreen(
                context,
                GroupInfo(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  adminName: fetchedAdmin, //changes made here so admin name appeared need to revisit this
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [Expanded(child: chatMessages()), messageInputField()],
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
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 5,
                ),
                itemBuilder: (context, index) {
                  var messageData = snapshot.data.docs[index];
                  DateTime messageDateTime =
                      DateTime.fromMillisecondsSinceEpoch(messageData['time']);
                  String formattedTime = DateFormat(
                    'hh:mm a',
                  ).format(messageDateTime);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MessageTile(
                        message: messageData['message'],
                        sender: messageData['sender'],
                        sentByMe: widget.userName == messageData['sender'],
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextFormField(
                controller: messageController,
                focusNode: messageFocusNode,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    messageController.text.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.send_sharp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
