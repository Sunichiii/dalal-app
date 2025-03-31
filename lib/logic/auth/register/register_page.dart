import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';
import '../../../presentation/screens/home/home_page.dart';
import '../../../presentation/widgets/widgets.dart';
import '../login/login_page.dart';
import 'bloc/register_bloc.dart';
import 'bloc/register_event.dart';
import 'bloc/register_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  String fullName = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      body: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            nextScreenReplaced(context, HomePage());
          } else if (state is RegisterFailure) {
            showSnackbar(context, Colors.red, state.error);
          }
        },
        builder: (context, state) {
          return state is RegisterLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          )
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
                      "Texty",
                      style: AppTextStyles.large
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Create your account to chat and explore!",
                      style: AppTextStyles.medium
                    ),
                    Image.asset("assets/images/register.png"),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Username",
                        labelStyle: AppTextStyles.small,
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          fullName = val;
                        });
                      },
                      validator: (val) =>
                      val!.isNotEmpty ? null : "Name cannot be empty",
                      style: AppTextStyles.small,
                    ),
                    SizedBox(height: 15),
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
                          backgroundColor:
                          Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            context.read<RegisterBloc>().add(
                              RegisterUser(
                                fullName: fullName,
                                email: email,
                                password: password,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Register",
                          style: AppTextStyles.medium
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style: AppTextStyles.small,
                        children: <TextSpan>[
                          TextSpan(
                            text: "Login Now",
                            style: AppTextStyles.small,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                nextScreen(context, LoginPage());
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
