import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import 'package:groupie_v2/presentation/widgets/widgets.dart';
import '../screens/chat/chat_page.dart';

class GroupTile extends StatefulWidget {
  final String userName;
  final String groupId;
  final String groupName;

  const GroupTile({
    super.key,
    required this.userName,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        nextScreen(
          context,
          ChatPage(
            groupId: widget.groupId,
            groupName: widget.groupName,
            userName: widget.userName,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Constants().primaryColor, // Light background for each tile
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Constants().secondaryColor,
            child: Text(
              widget.groupName.substring(0, 1).toUpperCase(), // First letter of the group name
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          title: Text(
            widget.groupName.toUpperCase(), // Uppercase group name
            style: AppTextStyles.medium
          ),
          subtitle: Text(
            "Joined the conversation as ${widget.userName}",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
