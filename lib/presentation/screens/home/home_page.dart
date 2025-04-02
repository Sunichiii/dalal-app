import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import '../../../core/services/auth_services.dart';
import '../../../core/services/database_service.dart';
import '../../../data/sources/helper_function.dart';
import '../../../logic/auth/login/login_page.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/widgets.dart';
import '../profile/profile_page.dart';
import '../search/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream<DocumentSnapshot>? groups;
  bool _isLoading = false;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  // string manipulation
  String getId(String res) => res.substring(0, res.indexOf("_"));

  String getName(String res) => res.substring(res.indexOf("_") + 1);

  gettingUserData() async {
    email = (await HelperFunctions.getUserEmailSF()) ?? "";
    userName = (await HelperFunctions.getUserNameSF()) ?? "";

    // Get user groups as stream
    final groupStream =
    DatabaseService(
      uid: FirebaseAuth.instance.currentUser!.uid,
    ).getUserGroups();

    setState(() {
      groups = groupStream;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      //Constants().backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(context, const SearchPage());
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "G R O U P S",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: <Widget>[
            Icon(
              CupertinoIcons.person_circle_fill,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 15),
            Text(
              userName,
              textAlign: TextAlign.center,
              style: AppTextStyles.medium,
            ),
            SizedBox(height: 20),
            Divider(height: 2),
            const SizedBox(height: 30),
            ListTile(
              onTap: () {},
              selectedColor: Theme.of(context).primaryColor,
              selected: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: const Icon(CupertinoIcons.group, color: Colors.white),
              title: Text(" G R O U P S",style: AppTextStyles.medium),
            ),
            ListTile(
              onTap: () {
                nextScreenReplaced(
                  context,
                  ProfilePage(userName: userName, email: email),
                );
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: const Icon(CupertinoIcons.person, color: Colors.white),
              title: Text("P R O F I L E", style: AppTextStyles.medium),
            ),
            ListTile(
              onTap: () async {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Constants().backGroundColor,
                      title: Text("Logout", style: AppTextStyles.medium),
                      content: Text(
                        "Are you sure you want to logout?",
                        style: AppTextStyles.small,
                      ),
                      actions: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                        ),
                        IconButton(
                          onPressed: () async {
                            await authService.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                                  (route) => false,
                            );
                          },
                          icon: const Icon(Icons.done, color: Colors.green),
                        ),
                      ],
                    );
                  },
                );
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: const Icon(
                CupertinoIcons.square_arrow_right,
                color: Colors.white,
              ),
              title: Text("L  O G O U T",style: AppTextStyles.medium),
            ),
          ],
        ),
      ),
      body: groupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          popUpDialog(context);
        },
        elevation: 0,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  void popUpDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: ((context, setState) {
            return AlertDialog(
              backgroundColor: Constants().backGroundColor,
              title: Text("Create a group", style: TextStyle(color: Colors.black),),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                      : TextField(
                    onChanged: (val) {
                      setState(() {
                        groupName = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName.isNotEmpty) {
                      setState(() => _isLoading = true);
                      await DatabaseService(
                        uid: FirebaseAuth.instance.currentUser!.uid,
                      ).createGroup(
                        userName,
                        FirebaseAuth.instance.currentUser!.uid,
                        groupName,
                      );
                      _isLoading = false;
                      Navigator.of(context).pop();
                      showSnackbar(
                        context,
                        Colors.green,
                        "Group created successfully.",
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    "Create",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget groupList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: groups,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final groupList = data['groups'] ?? [];

          if (groupList.isNotEmpty) {
            return ListView.builder(
              itemCount: groupList.length,
              itemBuilder: (context, index) {
                int reverseIndex = groupList.length - index - 1;
                return GroupTile(
                  groupId: getId(groupList[reverseIndex]),
                  groupName: getName(groupList[reverseIndex]).toUpperCase(),
                  userName: data['fullName'],
                );
              },
            );
          } else {
            return noGroupWidget();
          }
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }
      },
    );
  }

  Widget noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              popUpDialog(context);
            },
            child: Icon(Icons.add_circle, color: Colors.white, size: 75),
          ),
          const SizedBox(height: 20),
          Text(
            "You've not joined any groups. Tap the add icon to create a group or search using the top search button.",
            style: AppTextStyles.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
