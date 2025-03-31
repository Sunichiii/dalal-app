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
    try {
      var groupDoc = await DatabaseService().groupCollection.doc(widget.groupId).get();
      final data = groupDoc.data() as Map<String, dynamic>?;

      // Optional: simulate slight loading delay
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        requests = data?['groupRequests'] != null
            ? List.from(data!['groupRequests'])
            : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        requests = [];
        isLoading = false;
      });
    }
  }

  Future<void> approveRequest(String requestId) async {
    String userId = requestId.split("_")[0];
    String userName = requestId.split("_")[1];

    await DatabaseService().approveJoinRequest(
      widget.groupId,
      userId,
      userName,
    );

    fetchRequests();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User approved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Join Requests - ${widget.groupName}"),
      ),
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
              onPressed: () => approveRequest(requests[index]),
              child: const Text("Approve"),
            ),
          );
        },
      ),
    );
  }
}
