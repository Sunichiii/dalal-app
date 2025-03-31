import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import '../../../core/services/auth_services.dart';
import '../../../core/services/database_service.dart';
import '../../../presentation/screens/home/home_page.dart';
import '../../../presentation/widgets/widgets.dart';
import '../register/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = "";
  String password = "";
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black38,
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.blue))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 80,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "TEXTY",
                          style: AppTextStyles.large
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Login now to see what they are talking !",
                          style: AppTextStyles.medium
                        ),
                        Image.asset("assets/images/login.png"),
                        TextFormField(
                          decoration: textInputDecoration.copyWith(
                            labelText: "Email",
                            labelStyle: AppTextStyles.small,
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.white,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              email = val;
                            });
                          },
                          //validation
                          validator: (val) {
                            return RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                ).hasMatch(val!)
                                ? null
                                : "Please enter a valid email";
                          },
                          style: AppTextStyles.small,

                        ),

                        SizedBox(height: 15),
                        TextFormField(
                          obscureText: true,
                          decoration: textInputDecoration.copyWith(
                            labelText: "Password",
                            labelStyle: AppTextStyles.small,
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.white,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              password = val;
                            });
                          },
                          validator: (val) {
                            if (val!.length < 6) {
                              return "Password must be at least 6 characters";
                            } else {
                              return null;
                            }
                          },
                          style: AppTextStyles.small,
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants().primaryColor,
                              side: BorderSide(color: Colors.white, width: 2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              login();
                            },
                            child: Text(
                              "Sign In",
                              style: AppTextStyles.small
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: AppTextStyles.small,
                            children: <TextSpan>[
                              TextSpan(
                                text: "Register here",
                                style: AppTextStyles.small,
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        nextScreen(context, RegisterPage());
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  login() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await authService.loginWithEmailAndPassword(email, password).then((
        value,
      ) async {
        if (value == true) {
          QuerySnapshot snapshot = await DatabaseService(
            uid: FirebaseAuth.instance.currentUser!.uid,
          ).gettingUserData(email);

          //saving the values to the shared preferences
          await HelperFunctions.saveUserLoggedInStatus(true);
          await HelperFunctions.saveUserNameSF(email);
          await HelperFunctions.saveUserNameSF(
            snapshot.docs[0]['fullName']);
          nextScreenReplaced(context, HomePage());
        } else {
          showSnackbar(context, Colors.red, value);
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}
