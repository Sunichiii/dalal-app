import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
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
    final groupDoc =
        await DatabaseService().groupCollection.doc(widget.groupId).get();
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
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.black,
            title: Text("Assign Anonymous Name", style: AppTextStyles.medium,),
            content: TextField(
              controller: nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. BlueWolf, CuriousCat",
                hintStyle: AppTextStyles.small,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: Colors.red),),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Approve", style: TextStyle(color: Colors.white),),
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
      backgroundColor: Constants().backGroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Constants().primaryColor,
        title: Text(
          "Join Requests - ${widget.groupName}",
          style: AppTextStyles.medium,
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
              ?  Center(child: Text("No join requests", style: AppTextStyles.large,))
              : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  String name = requests[index].split("_")[1];
                  return ListTile(
                    title: Text(name, style: AppTextStyles.medium),
                    trailing: ElevatedButton(
                      onPressed: () => showAssignNameDialog(requests[index]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants().primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Approve", style: AppTextStyles.medium),
                    ),
                  );
                },
              ),
    );
  }
}
