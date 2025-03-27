import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import '../../../core/services/database_service.dart';
import '../../widgets/widgets.dart';
import '../chat/chat_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  bool hasUserSearched = false;
  String userName = "";
  User? user;
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    getCurrentUserIdandName();
  }

  String getName(String member) {
    if (member.isEmpty || !member.contains("_")) return "Unknown";
    return member.substring(member.indexOf("_") + 1);
  }

  String getId(String member) {
    if (member.isEmpty || !member.contains("_")) return "Unknown ID";
    return member.substring(0, member.indexOf("_"));
  }

  getCurrentUserIdandName() async {
    await HelperFunctions.getUserNameSF().then((value) {
      setState(() {
        userName = value ?? "";
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Search Group",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Search for a group",
                      hintStyle: TextStyle(color: Colors.white),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    initiateSearchMethod();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : groupList(),
        ],
      ),
    );
  }

  initiateSearchMethod() async {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      await DatabaseService().searchByName(searchController.text).then((
        snapshot,
      ) {
        setState(() {
          searchSnapshot = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  Widget groupList() {
    return hasUserSearched
        ? searchSnapshot != null && searchSnapshot!.docs.isNotEmpty
            ? ListView.builder(
              itemCount: searchSnapshot!.docs.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return groupTile(
                  userName,
                  searchSnapshot!.docs[index]['groupId'],
                  searchSnapshot!.docs[index]['groupName'],
                  searchSnapshot!.docs[index]['admin'],
                );
              },
            )
            : const Center(child: Text("No Groups Found"))
        : Container();
  }

  joinedOrNot(String userName, groupId, groupName, admin) async {
    await DatabaseService(
      uid: user!.uid,
    ).isUserJoined(groupName, groupId, userName).then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  Widget groupTile(
    String userName,
    String groupId,
    String groupName,
    String admin,
  ) {
    joinedOrNot(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      title: Text(groupName, style: TextStyle(fontWeight: FontWeight.w600)),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(groupName.substring(0, 1).toUpperCase()),
      ),
      subtitle: Text("Admin: ${getName(admin)}"),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService().sendJoinRequest(groupId, userName, user!.uid);
          if (isJoined) {
            setState(() {
              isJoined = !isJoined;
            });
            showSnackbar(
              context,
              Colors.green,
              "Successfully joined the group",
            );
            Future.delayed(Duration(seconds: 2), () {
              nextScreen(
                context,
                ChatPage(
                  groupId: groupId,
                  groupName: groupName,
                  userName: userName,
                ),
              );
            });
          } else {
            setState(() {
              isJoined = !isJoined;
              showSnackbar(context, Colors.blue, "Sent a request to $groupName");
            });
          }
        },
        child:
            isJoined
                ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                    border: Border.all(color: Colors.white),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Joined",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Request Join?",
                    style: TextStyle(fontSize: 16, color: Colors.white),

                  ),
                ),
      ),
    );
  }
}
