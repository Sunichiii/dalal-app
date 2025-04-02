import 'package:flutter/material.dart';
import 'package:groupie_v2/core/services/database_service.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';

class GroupInfoDialogs {
  static Future<void> showLeaveConfirmation({
    required BuildContext context,
    required VoidCallback onLeaveConfirmed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Exit", style: AppTextStyles.large),
        content: Text(
          "Are you sure you want to leave this group?",
          style: AppTextStyles.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLeaveConfirmed();
            },
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static Future<void> showAdminTransferDialog({
    required BuildContext context,
    required VoidCallback onContinue,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Constants().backGroundColor,
        title: Text("Transfer Admin Rights", style: AppTextStyles.large),
        content: Text(
          "As admin, you must transfer admin rights before leaving. "
              "Select a new admin from the group members.",
          style: AppTextStyles.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onContinue();
            },
            child: const Text("Continue", style: TextStyle(color: Colors.red),),
          ),
        ],
      ),
    );
  }

  static Future<void> showMemberSelectionDialog({
    required BuildContext context,
    required Stream membersStream,
    required String adminName,
    required String groupId,
    required String currentUserId,
    required VoidCallback onLeaveConfirmed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => StreamBuilder(
        stream: membersStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final members = List.from(data?['members'] ?? [])
              .where((m) => m != adminName)
              .toList();

          if (members.isEmpty) {
            return AlertDialog(
              title: Text("No Members", style: AppTextStyles.large),
              content: Text(
                "There are no other members to transfer admin rights to.",
                style: AppTextStyles.small,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Text("Select New Admin", style: AppTextStyles.large),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberId = _getId(member);
                  final memberName = _getName(member);
                  final anonName = data?['groupAnonNames']?[memberId] ?? "Anonymous";

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(anonName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(anonName),
                    onTap: () async {
                      try {
                        await DatabaseService(uid: currentUserId).transferAdminRights(
                          groupId: groupId,
                          newAdminId: memberId,
                          newAdminName: memberName,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          onLeaveConfirmed();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Transfer failed: ${e.toString()}")),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<bool?> showRemoveMemberConfirmation({
    required BuildContext context,
    required String memberName,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Constants().backGroundColor,
        title: Text("Remove Member", style: AppTextStyles.large),
        content: Text(
          "Are you sure you want to remove $memberName from the group?",
          style: AppTextStyles.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.green),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static String _getName(String member) =>
      member.contains('_') ? member.split('_')[1] : "Unknown";

  static String _getId(String member) =>
      member.contains('_') ? member.split('_')[0] : "Unknown ID";
}