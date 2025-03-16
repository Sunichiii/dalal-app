import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/pages/auth/login/login_page.dart';
import 'package:groupie_v2/pages/profile/profile_bloc.dart';
import 'package:groupie_v2/pages/profile/profile_event.dart';
import 'package:groupie_v2/pages/profile/profile_page.dart';
import 'package:groupie_v2/pages/profile/profile_state.dart';
import 'package:groupie_v2/pages/search_page.dart';
import 'package:groupie_v2/services/auth_services.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              ProfileBloc(authService: AuthService())..add(FetchProfileData()),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                );
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
        body: Center(
          child: Text("Home Page Content Here"),
        ), // Replace with your home page content
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          String userName = "Loading...";
          String email = "Loading...";

          if (state is ProfileLoaded) {
            userName = state.userName;
            email = state.email;
          } else if (state is ProfileError) {
            userName = "Error";
            email = "Error";
          }

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 50),
            children: <Widget>[
              Icon(Icons.account_circle, size: 150, color: Colors.grey),
              SizedBox(height: 15),
              Text(
                userName,
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

              // Groups Page
              ListTile(
                onTap: () {},
                selectedColor: Theme.of(context).primaryColor,
                selected: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: Icon(CupertinoIcons.group_solid, size: 30),
                title: Text(
                  "Groups",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Profile Page
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
                selectedColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: Icon(CupertinoIcons.profile_circled, size: 30),
                title: Text(
                  "Profile",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Logout Option
              ListTile(
                onTap: () => _showLogoutDialog(context),
                selectedColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: Icon(Icons.exit_to_app, size: 30),
                title: Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to Logout?"),
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
}
