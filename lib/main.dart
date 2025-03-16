import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/helper/helper_function.dart';
import 'package:groupie_v2/pages/auth/login/bloc/login_bloc.dart';
import 'package:groupie_v2/pages/auth/login/login_page.dart';
import 'package:groupie_v2/pages/auth/register/bloc/register_bloc.dart';
import 'package:groupie_v2/pages/home_page.dart';
import 'package:groupie_v2/services/auth_services.dart';
import 'package:groupie_v2/shared/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Run Firebase initialization for web
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: Constants.apiKey,
        appId: Constants.appId,
        messagingSenderId: Constants.messagingSenderId,
        projectId: Constants.projectId,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    getUserLoggedInStatus();
  }

  getUserLoggedInStatus() async {
    await HelperFunctions.getUserLoggedInStatus().then((value) {
      if (value != null) {
        setState(() {
          _isSignedIn = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RegisterBloc(authService: AuthService()),
        ),
        BlocProvider(
          create: (context) => LoginBloc(authService: AuthService()),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primaryColor: Constants().primaryColor,
          scaffoldBackgroundColor: Colors.white,
        ),
        debugShowCheckedModeBanner: false,
        home: _isSignedIn ? HomePage() : LoginPage(),
      ),
    );
  }
}
