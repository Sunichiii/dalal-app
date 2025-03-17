import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/pages/auth/login/login_page.dart';
import 'package:groupie_v2/pages/auth/register/bloc/register_bloc.dart';
import 'package:groupie_v2/pages/auth/register/bloc/register_event.dart';
import 'package:groupie_v2/pages/auth/register/bloc/register_state.dart';
import 'package:groupie_v2/pages/home/home_page.dart';
import '../../../widgets/widgets.dart';

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
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Create your account to chat and explore",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                    ),
                    Image.asset("assets/images/register.png"),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Username",
                        prefixIcon: Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          fullName = val;
                        });
                      },
                      validator: (val) =>
                      val!.isNotEmpty ? null : "Name cannot be empty",
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Email",
                        prefixIcon: Icon(
                          Icons.email,
                          color: Theme.of(context).primaryColor,
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
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      obscureText: true,
                      decoration: textInputDecoration.copyWith(
                        labelText: "Password",
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Theme.of(context).primaryColor,
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
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style:
                        TextStyle(color: Colors.black, fontSize: 14),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Login Now",
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
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
