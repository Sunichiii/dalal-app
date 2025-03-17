/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/pages/auth/login/login_page.dart';
import 'package:groupie_v2/pages/profile/bloc/profile_bloc.dart';
import 'package:groupie_v2/pages/profile/bloc/profile_event.dart';
import 'package:groupie_v2/pages/profile/profile_page.dart';
import 'package:groupie_v2/pages/profile/bloc/profile_state.dart';
import 'package:groupie_v2/pages/search/search_page.dart';
import 'package:groupie_v2/services/auth_services.dart';
import 'package:groupie_v2/services/database_service.dart';
import 'package:groupie_v2/widgets/group_tile.dart';

import '../../helper/helper_function.dart';
import '../../widgets/widgets.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";
  String userName = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  // Extracting group ID and group name from Firestore group format
  String getId(String res) {
    return res.split("_")[0]; // Extract the ID before "_"
  }

  String getName(String res) {
    return res.split("_")[1]; // Extract the Name after "_"
  }

  gettingUserData() async {
    String? fetchedUserName = await HelperFunctions.getUserNameSF();
    setState(() {
      userName = fetchedUserName ?? "Unknown"; // Prevent null issues
    });

    // Fetch user groups from Firestore
    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserGroup()
        .then((snapshot) {
      setState(() {
        groups = snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(authService: AuthService())..add(FetchProfileData()),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
              },
              icon: Icon(Icons.search),
              color: Colors.white,
            ),
          ],
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: true,
          title: Text(
            "Groups",
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: _buildDrawer(context),
        body: groupList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            popUpDialog(context);
          },
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          String drawerUserName = "Loading...";
          String email = "Loading...";

          if (state is ProfileLoaded) {
            drawerUserName = state.userName;
            email = state.email;
          } else if (state is ProfileError) {
            drawerUserName = "Error";
            email = "Error";
          }

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 50),
            children: <Widget>[
              Icon(Icons.account_circle, size: 150, color: Colors.grey),
              SizedBox(height: 15),
              Text(
                drawerUserName,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 30),
              const Divider(height: 2),

              ListTile(
                onTap: () {},
                selectedColor: Theme.of(context).primaryColor,
                selected: true,
                leading: Icon(CupertinoIcons.group_solid, size: 30),
                title: Text("Groups", style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                },
                selectedColor: Theme.of(context).primaryColor,
                leading: Icon(CupertinoIcons.profile_circled, size: 30),
                title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              ListTile(
                onTap: () => _showLogoutDialog(context),
                selectedColor: Theme.of(context).primaryColor,
                leading: Icon(Icons.exit_to_app, size: 30),
                title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error loading groups"));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data?.data() ?? {};

        if (data.containsKey('groups') && data['groups'] != null && data['groups'].length > 0) {
          return ListView.builder(
            itemCount: data['groups'].length,
            itemBuilder: (context, index) {
              return GroupTile(
                groupId: getId(data['groups'][index]),
                username: userName,
                groupName: getName(data['groups'][index]),
              );
            },
          );
        } else {
          return noGroupWidget();
        }
      },
    );
  }

  Widget noGroupWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => popUpDialog(context),
            child: Icon(Icons.add_circle, color: Colors.grey[700], size: 75),
          ),
          SizedBox(height: 20),
          Text(
            "You haven't joined or created any groups yet.\nTap the add icon to create one.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                context.read<ProfileBloc>().add(LogoutUser());
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              child: Text("Logout", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void popUpDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Create a Group"),
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
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });

                      // Ensure username is assigned before creating the group
                      if (userName.isEmpty) {
                        showSnackbar(context, Colors.red, "Username not found!");
                        return;
                      }

                      await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                          .createGroup(
                        userName,
                        FirebaseAuth.instance.currentUser!.uid,
                        groupName,
                      )
                          .whenComplete(() {
                        setState(() {
                          _isLoading = false;
                        });
                      });

                      Navigator.of(context).pop();
                      showSnackbar(context, Colors.green, "Group created successfully.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text("Create", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

 */


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/widgets/widgets.dart';

import '../../helper/helper_function.dart';
import '../../services/auth_services.dart';
import '../../services/database_service.dart';
import '../../widgets/group_tile.dart';
import '../auth/login/login_page.dart';
import '../profile/profile_page.dart';
import '../search/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  // string manipulation
  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  String getName(String res) {
    return res.substring(res.indexOf("_") + 1);
  }

  gettingUserData() async {
    await HelperFunctions.getUserEmailSF().then((value) {
      setState(() {
        email = value!;
      });
    });
    await HelperFunctions.getUserNameSF().then((val) {
      setState(() {
        userName = val!;
      });
    });
    // getting the list of snapshots in our stream
    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserGroups()
        .then((snapshot) {
      setState(() {
        groups = snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                nextScreen(context, const SearchPage());
              },
              icon: const Icon(
                Icons.search,
              ))
        ],
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Groups",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 27),
        ),
      ),
      drawer: Drawer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 50),
            children: <Widget>[
              Icon(
                Icons.account_circle,
                size: 150,
                color: Colors.grey[700],
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                userName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30,
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                onTap: () {},
                selectedColor: Theme.of(context).primaryColor,
                selected: true,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: const Icon(Icons.group),
                title: const Text(
                  "Groups",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ListTile(
                onTap: () {
                  nextScreenReplaced(
                      context,
                      ProfilePage(
                        userName: userName,
                        email: email,
                      ));
                },
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: const Icon(Icons.group),
                title: const Text(
                  "Profile",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ListTile(
                onTap: () async {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Logout"),
                          content: const Text("Are you sure you want to logout?"),
                          actions: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await authService.signOut();
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => const LoginPage()),
                                        (route) => false);
                              },
                              icon: const Icon(
                                Icons.done,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        );
                      });
                },
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: const Icon(Icons.exit_to_app),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.black),
                ),
              )
            ],
          )),
      body: groupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          popUpDialog(context);
        },
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  popUpDialog(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: const Text(
                "Create a group",
                textAlign: TextAlign.left,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading == true
                      ? Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor),
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
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(20)),
                        errorBorder: OutlineInputBorder(
                            borderSide:
                            const BorderSide(color: Colors.red),
                            borderRadius: BorderRadius.circular(20)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName != "") {
                      setState(() {
                        _isLoading = true;
                      });
                      DatabaseService(
                          uid: FirebaseAuth.instance.currentUser!.uid)
                          .createGroup(userName,
                          FirebaseAuth.instance.currentUser!.uid, groupName)
                          .whenComplete(() {
                        _isLoading = false;
                      });
                      Navigator.of(context).pop();
                      showSnackbar(
                          context, Colors.green, "Group created successfully.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                  child: const Text("CREATE"),
                )
              ],
            );
          }));
        });
  }

  groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot snapshot) {
        // make some checks
        if (snapshot.hasData) {
          if (snapshot.data['groups'] != null) {
            if (snapshot.data['groups'].length != 0) {
              return ListView.builder(
                itemCount: snapshot.data['groups'].length,
                itemBuilder: (context, index) {
                  int reverseIndex = snapshot.data['groups'].length - index - 1;
                  return GroupTile(
                      groupId: getId(snapshot.data['groups'][reverseIndex]),
                      groupName: getName(snapshot.data['groups'][reverseIndex]),
                      userName: snapshot.data['fullName']);
                },
              );
            } else {
              return noGroupWidget();
            }
          } else {
            return noGroupWidget();
          }
        } else {
          return Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor),
          );
        }
      },
    );
  }

  noGroupWidget() {
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
            child: Icon(
              Icons.add_circle,
              color: Colors.grey[700],
              size: 75,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "You've not joined any groups, tap on the add icon to create a group or also search from top search button.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}