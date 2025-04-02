import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/core/services/database_service.dart';
import '../../../core/shared/constants.dart';
import '../../../core/shared/textstyles.dart';
import '../group_request/group_request_page.dart';
import '../home/home_page.dart';
import 'group_info_dialogs.dart';
import 'group_info_widgets.dart';

class GroupInfo extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminName;

  const GroupInfo({
    super.key,
    required this.adminName,
    required this.groupName,
    required this.groupId,
  });

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Stream? membersStream;
  bool isCurrentUserAdmin = false;

  @override
  void initState() {
    super.initState();
    _getGroupMembers();
    _checkIfCurrentUserIsAdmin();
  }

  void _getGroupMembers() {
    setState(() {
      membersStream = DatabaseService(uid: currentUserId).getGroupMembers(widget.groupId);
    });
  }

  void _checkIfCurrentUserIsAdmin() {
    setState(() {
      isCurrentUserAdmin = (currentUserId == _getId(widget.adminName));
    });
  }

  String _getId(String member) => member.contains('_') ? member.split('_')[0] : "Unknown ID";

  Future<void> _handleLeaveGroup() async {
    try {
      await DatabaseService(uid: currentUserId).leaveGroup(widget.groupId, widget.groupName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully left the group")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await GroupInfoDialogs.showRemoveMemberConfirmation(
      context: context,
      memberName: memberName,
    );

    if (confirmed == true) {
      try {
        await DatabaseService(uid: currentUserId).removeMemberFromGroup(
          groupId: widget.groupId,
          groupName: widget.groupName,
          memberId: memberId,
          memberName: memberName,
          fullMemberString: "${memberId}_$memberName",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Member removed successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error removing member: ${e.toString()}")),
          );
        }
      }
    }
  }

  void _handleExitAction() {
    if (isCurrentUserAdmin) {
      GroupInfoDialogs.showAdminTransferDialog(
        context: context,
        onContinue: () => _showMemberSelectionDialog(),
      );
    } else {
      GroupInfoDialogs.showLeaveConfirmation(
        context: context,
        onLeaveConfirmed: _handleLeaveGroup,
      );
    }
  }

  void _showMemberSelectionDialog() {
    GroupInfoDialogs.showMemberSelectionDialog(
      context: context,
      membersStream: membersStream!,
      adminName: widget.adminName,
      groupId: widget.groupId,
      currentUserId: currentUserId,
      onLeaveConfirmed: _handleLeaveGroup,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      appBar: GroupInfoWidgets.buildAppBar(
        context: context,
        isCurrentUserAdmin: isCurrentUserAdmin,
        groupId: widget.groupId,
        groupName: widget.groupName,
        onBackPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        ),
        onTransferPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupRequestsPage(
                groupId: widget.groupId,
                groupName: widget.groupName,
              ),
            ),
          );
        },
        onExitPressed: _handleExitAction,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GroupInfoWidgets.buildGroupHeader(
              groupName: widget.groupName,
              adminName: widget.adminName,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Members", style: AppTextStyles.medium),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: membersStream,
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasError) {
                    return GroupInfoWidgets.buildErrorWidget();
                  }

                  if (!snapshot.hasData ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return GroupInfoWidgets.buildLoadingIndicator(context);
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  if (data == null) {
                    return GroupInfoWidgets.buildNoDataWidget();
                  }

                  return GroupInfoWidgets.buildMemberList(
                    data: data,
                    adminName: widget.adminName,
                    isCurrentUserAdmin: isCurrentUserAdmin,
                    onRemoveMember: _removeMember,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}