import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';

class GroupInfoWidgets {
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required bool isCurrentUserAdmin,
    required String groupId,
    required String groupName,
    required VoidCallback onBackPressed,
    required VoidCallback onTransferPressed,
    required VoidCallback onExitPressed,
  }) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed,
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      title: const Text("GROUP INFO", style: TextStyle(color: Colors.white)),
      actions: [
        if (isCurrentUserAdmin)
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: onTransferPressed,
          ),
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          onPressed: onExitPressed,
        ),
      ],
    );
  }

  static Widget buildGroupHeader({
    required String groupName,
    required String adminName,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Constants().primaryColor,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Constants().secondaryColor,
            child: Text(
              groupName.substring(0, 1).toUpperCase(),
              style: AppTextStyles.medium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Group: $groupName",
                  style: AppTextStyles.medium.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  "Admin: ${_getName(adminName)}",
                  style: AppTextStyles.small.copyWith(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildMemberList({
    required Map<String, dynamic> data,
    required String adminName,
    required bool isCurrentUserAdmin,
    required Function(String, String) onRemoveMember,
  }) {
    List<dynamic> members = data['members'] ?? [];
    members.removeWhere((member) => member == adminName);

    if (members.isEmpty) {
      return Center(
        child: Text(
          "No other members in this group",
          style: AppTextStyles.medium,
        ),
      );
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final memberId = _getId(member);
        final memberName = _getName(member);
        final anonName = data['groupAnonNames']?[memberId] ?? "Anonymous";

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Constants().primaryColor,
            child: Text(
              anonName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(anonName, style: AppTextStyles.medium,),
          subtitle: Text(memberId, style: AppTextStyles.small,),
          trailing: isCurrentUserAdmin
              ? IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            onPressed: () => onRemoveMember(memberId, memberName),
          )
              : null,
        );
      },
    );
  }

  static Widget buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  static Widget buildErrorWidget() {
    return Center(
      child: Text(
        "Error loading members",
        style: AppTextStyles.medium,
      ),
    );
  }

  static Widget buildNoDataWidget() {
    return Center(
      child: Text(
        "No group data found",
        style: AppTextStyles.medium,
      ),
    );
  }

  static String _getName(String member) =>
      member.contains('_') ? member.split('_')[1] : "Unknown";

  static String _getId(String member) =>
      member.contains('_') ? member.split('_')[0] : "Unknown ID";
}