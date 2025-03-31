import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

class GroupRequestsPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupRequestsPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupRequestsPage> createState() => _GroupRequestsPageState();
}

class _GroupRequestsPageState extends State<GroupRequestsPage> {
  List<dynamic> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    final groupDoc = await DatabaseService().groupCollection.doc(widget.groupId).get();
    setState(() {
      requests = groupDoc['groupRequests'] ?? [];
      isLoading = false;
    });
  }

  void showAssignNameDialog(String requestId) {
    final userId = requestId.split("_")[0];
    final userName = requestId.split("_")[1];
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Assign Anonymous Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "e.g. BlueWolf, CuriousCat",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Approve"),
            onPressed: () async {
              String anonName = nameController.text.trim();
              if (anonName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name cannot be empty")),
                );
                return;
              }

              Navigator.pop(context); // Close dialog

              await DatabaseService().approveJoinRequest(
                groupId: widget.groupId,
                groupName: widget.groupName,
                userId: userId,
                userName: userName,
                assignedName: anonName,
              );

              fetchRequests(); // Refresh list

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$anonName has been approved")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Requests - ${widget.groupName}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No join requests"))
          : ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          String name = requests[index].split("_")[1];
          return ListTile(
            title: Text(name),
            trailing: ElevatedButton(
              onPressed: () => showAssignNameDialog(requests[index]),
              child: const Text("Approve"),
            ),
          );
        },
      ),
    );
  }
}
