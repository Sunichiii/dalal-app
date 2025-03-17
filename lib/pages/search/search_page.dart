import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/helper/helper_function.dart';
import 'package:groupie_v2/services/database_service.dart';

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
  bool isJoined =false;

  @override
  void initState() {
    super.initState();
    getCurrentUserIdandName();
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
          isLoading ? const Center(child: CircularProgressIndicator()) : groupList(),
        ],
      ),
    );
  }

  initiateSearchMethod() async {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      await DatabaseService().searchByName(searchController.text).then((snapshot) {
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

  joinedOrNot(String userName, groupId, groupName, admin)async{
    await DatabaseService(uid: user!.uid).isUserJoined(groupName, groupId, userName).then((value){
      setState(() {
        isJoined =value;
      });
    });
  }


  Widget groupTile(String userName, String groupId, String groupName, String admin) {
    joinedOrNot (userName, groupId, groupName, admin);
    return ListTile(
      title: Text(groupName),
      subtitle: Text("Admin: $admin"),
      trailing: ElevatedButton(
        onPressed: () {
          // Handle group join or more details
        },
        child: const Text("Join"),
      ),
    );
  }
}
