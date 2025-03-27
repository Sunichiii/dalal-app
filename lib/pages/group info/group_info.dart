import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/widgets.dart';
import '../group_request/group_request_page.dart';
import '../home/home_page.dart';

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
    _checkIfCurrentUserIsAdmin(); // admin check happens early
  }

  void _getGroupMembers() async {
    final stream =
    DatabaseService(uid: currentUserId).getGroupMembers(widget.groupId);
    setState(() {
      membersStream = stream;
    });
  }

  void _checkIfCurrentUserIsAdmin() {
    final adminId = getId(widget.adminName);
    setState(() {
      isCurrentUserAdmin = (currentUserId == adminId);
    });
  }

  String getName(String member) =>
      member.contains('_') ? member.split('_')[1] : "Unknown";

  String getId(String member) =>
      member.contains('_') ? member.split('_')[0] : "Unknown ID";

  void _exitGroup() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit"),
        content: const Text("Are you sure you want to exit the group?"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.red),
          ),
          IconButton(
            onPressed: () async {
              await DatabaseService(uid: currentUserId).toggleGroupJoin(
                widget.groupId,
                getName(widget.adminName),
                widget.groupName,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You have left the group")),
                );
                nextScreenReplaced(context, const HomePage());
              }
            },
            icon: const Icon(Icons.done, color: Colors.green),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back, color: Colors.white),
        onPressed: () {
          nextScreenReplaced(context, const HomePage());
        },
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      title: const Text("GROUP INFO", style: TextStyle(color: Colors.white)),
      actions: [
        if (isCurrentUserAdmin)
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: () {
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
          ),
        IconButton(
          onPressed: _exitGroup,
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMemberList(Map<String, dynamic> data) {
    List<dynamic> members = data['members'] ?? [];

    // Remove admin from member list
    members.removeWhere((member) => member == widget.adminName);

    if (members.isEmpty) {
      return const Center(child: Text("NO MEMBERS"));
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        String member = members[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                getName(member).substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(getName(member)),
            subtitle: Text(getId(member)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          nextScreenReplaced(context, const HomePage());
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(), //  uses extracted method
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder(
            stream: membersStream,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text("Something went wrong: ${snapshot.error}"));
              }

              if (!snapshot.hasData ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child:
                  CircularProgressIndicator(color: Theme.of(context).primaryColor),
                );
              }

              final data = snapshot.data?.data();
              if (data == null) return const Center(child: Text("No data"));

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            widget.groupName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Group: ${widget.groupName}",
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Text(
                              "Admin: ${widget.adminName.contains("_") ? getName(widget.adminName) : widget.adminName}",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Members",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Expanded(child: _buildMemberList(data)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
