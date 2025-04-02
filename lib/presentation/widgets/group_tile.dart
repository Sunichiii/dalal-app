import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import 'package:groupie_v2/presentation/widgets/widgets.dart';
import '../screens/chat/chat_page.dart';

class GroupTile extends StatelessWidget {
  final String userName;
  final String groupId;
  final String groupName;
  final String? lastMessage;
  final String? lastMessageSender;
  final String? lastMessageTime;

  const GroupTile({
    super.key,
    required this.userName,
    required this.groupId,
    required this.groupName,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            nextScreen(
              context,
              ChatPage(
                groupId: groupId,
                groupName: groupName,
                userName: userName,
              ),
            );
          },
          splashColor: Constants().primaryColor,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Constants().primaryColor,
                        Constants().secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      groupName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: AppTextStyles.medium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (lastMessage != null && lastMessageSender != null)
                        Text(
                          '$lastMessageSender: $lastMessage',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Tap to start chatting',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // Last message time or status
                if (lastMessageTime != null)
                  Text(
                    lastMessageTime!,
                    style: AppTextStyles.small.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}