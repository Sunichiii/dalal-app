import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import '../../../core/services/auth_services.dart';
import '../../widgets/widgets.dart';
import '../home/home_page.dart';

class ProfilePage extends StatefulWidget {
  String userName;
  String email;

  ProfilePage({super.key, required this.email, required this.userName});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            nextScreen(context, HomePage());
          },
          child: Icon(CupertinoIcons.back),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        title: const Text(
          "P R O F I L E",
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 170),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.account_circle,
              size: 150,
              color: Constants().primaryColor,
            ),
            const SizedBox(height: 15),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Full Name", style: AppTextStyles.medium),
                Text(widget.userName, style: AppTextStyles.medium),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Email", style: AppTextStyles.medium),
                Text(widget.email, style: AppTextStyles.medium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
