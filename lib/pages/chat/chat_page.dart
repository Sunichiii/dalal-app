import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/pages/group%20info/group_info.dart';
import 'package:groupie_v2/services/database_service.dart';
import 'package:groupie_v2/widgets/widgets.dart';

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
  Stream<QuerySnapshot>? chats;
  String admin = "";

  @override
  void initState() {
    super.initState();
    getChatandAdmin();
  }

  getChatandAdmin() async {
    chats = DatabaseService().getChats(widget.groupId);
    String adminName = await DatabaseService().getGroupAdmin(widget.groupId);
    setState(() {
      admin = adminName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(widget.groupName),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(
                context,
                GroupInfo(
                  groupName: widget.groupName,
                  groupId: widget.groupId,
                  adminName: admin,
                ),
              );
            },
            icon: Icon(Icons.info),
          ),
        ],
      ),
    );
  }
}
