import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:groupie_v2/core/services/auth_services.dart';
import 'package:groupie_v2/core/services/database_service.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import 'package:groupie_v2/presentation/widgets/group_tile.dart';
import 'package:groupie_v2/presentation/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/sources/helper_function.dart';
import '../profile/profile_page.dart';



import '../search/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  String profilePic = "";
  AuthService authService = AuthService();
  Stream<DocumentSnapshot>? groups;
  bool _isLoading = false;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  String getId(String res) => res.substring(0, res.indexOf("_"));
  String getName(String res) => res.substring(res.indexOf("_") + 1);

  gettingUserData() async {
    email = (await HelperFunctions.getUserEmailSF()) ?? "";
    userName = (await HelperFunctions.getUserNameSF()) ?? "";
    //profilePic = (await HelperFunctions.getProfilePicSF()) ?? "";

    final groupStream = DatabaseService(
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
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Your Groups",
                style: AppTextStyles.large.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Constants().primaryColor,
                      Constants().secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => nextScreen(context, const SearchPage()),
              ),
            ],
          ),
          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // User Profile Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => nextScreen(
                        context,
                        ProfilePage(userName: userName, email: email),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Constants().primaryColor,
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(profilePic)
                                  : null,
                              child: profilePic.isEmpty
                                  ? Icon(Icons.person, size: 30, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: AppTextStyles.medium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: AppTextStyles.small.copyWith(
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Groups List
          groups != null
              ? StreamBuilder<DocumentSnapshot>(
            stream: groups,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return SliverToBoxAdapter(
                  child: noGroupWidget(),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final groupList = data['groups'] ?? [];

              if (groupList.isEmpty) {
                return SliverToBoxAdapter(
                  child: noGroupWidget(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    int reverseIndex = groupList.length - index - 1;
                    return GroupTile(
                      groupId: getId(groupList[reverseIndex]),
                      groupName: getName(groupList[reverseIndex]),
                      userName: data['fullName'],
                    );
                  },
                  childCount: groupList.length,
                ),
              );
            },
          )
              : const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(),
        backgroundColor: Constants().primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Constants().backGroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Create New Group",
                  style: AppTextStyles.large.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (val) => groupName = val,
                  style: AppTextStyles.medium,
                  decoration: InputDecoration(
                    hintText: "Group name",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "Cancel",
                          style: AppTextStyles.medium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
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
                            setState(() => _isLoading = false);
                            Navigator.pop(context);
                            showSnackbar(
                              context,
                              Colors.green,
                              "Group created successfully",
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants().primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Create",
                          style: AppTextStyles.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget noGroupWidget() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_groups.png', // Add your own asset
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            "No Groups Yet",
            style: AppTextStyles.large.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Tap the + button to create your first group or search for existing ones",
            style: AppTextStyles.medium.copyWith(
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}