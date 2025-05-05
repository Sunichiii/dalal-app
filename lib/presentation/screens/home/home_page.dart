import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import '../../../core/services/auth_services.dart';
import '../../../logic/auth/login/login_page.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/widgets.dart';
import '../profile/profile_page.dart';
import '../search/search_page.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String groupName = "";
  final authService = AuthService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadUserData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => nextScreen(context, const SearchPage()),
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
      drawer: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            return buildDrawer(context, state.userName, state.email);
          } else {
            return const Drawer(child: Center(child: CircularProgressIndicator()));
          }
        },
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            showSnackbar(context, Colors.red, state.message);
          } else if (state is GroupCreated) {
            showSnackbar(context, Colors.green, "Group created successfully.");
          }
        },
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeLoaded) {
            return groupList(state.groupsStream, state.userName);
          } else {
            return const Center(child: Text("Something went wrong"));
          }
        },
      ),
      floatingActionButton: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            return FloatingActionButton(
              onPressed: () => popUpDialog(context, state.userName, state.email),
              elevation: 0,
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget buildDrawer(BuildContext context, String userName, String email) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 50),
        children: [
          const Icon(CupertinoIcons.person_circle_fill, size: 120, color: Colors.white),
          const SizedBox(height: 15),
          Text(userName, textAlign: TextAlign.center, style: AppTextStyles.medium),
          const SizedBox(height: 20),
          const Divider(height: 2),
          const SizedBox(height: 30),
          ListTile(
            selected: true,
            selectedColor: Theme.of(context).primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: const Icon(CupertinoIcons.group, color: Colors.white),
            title: Text("G R O U P S", style: AppTextStyles.medium),
          ),
          ListTile(
            onTap: () {
              nextScreenReplaced(context, ProfilePage(userName: userName, email: email));
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: const Icon(CupertinoIcons.person, color: Colors.white),
            title: Text("P R O F I L E", style: AppTextStyles.medium),
          ),
          ListTile(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: Constants().backGroundColor,
                  title: Text("Logout", style: AppTextStyles.medium),
                  content: Text("Are you sure you want to logout?", style: AppTextStyles.small),
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                    ),
                    IconButton(
                      onPressed: () async {
                        await authService.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.done, color: Colors.green),
                    ),
                  ],
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.white),
            title: Text("L O G O U T", style: AppTextStyles.medium),
          ),
        ],
      ),
    );
  }

  Widget groupList(Stream<DocumentSnapshot> stream, String userName) {
    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
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
                  groupId: groupList[reverseIndex].split('_')[0],
                  groupName: groupList[reverseIndex].split('_')[1],
                  userName: userName,
                );
              },
            );
          } else {
            return noGroupWidget();
          }
        } else {
          return const Center(child: CircularProgressIndicator());
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
            onTap: () => context.read<HomeBloc>().add(LoadUserData()),
            child: const Icon(Icons.add_circle, color: Colors.white, size: 75),
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

  void popUpDialog(BuildContext context, String userName, String email) {
    String newGroupName = "";
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Constants().backGroundColor,
        title: const Text("Create a group", style: TextStyle(color: Colors.white)),
        content: TextField(
          onChanged: (val) => newGroupName = val,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(20),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newGroupName.isNotEmpty) {
                Navigator.of(context).pop();
                context.read<HomeBloc>().add(CreateGroup(
                  groupName: newGroupName,
                  userId: user!.uid,
                  userName: userName,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
