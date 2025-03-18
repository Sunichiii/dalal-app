import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/helper/helper_function.dart';
import 'package:groupie_v2/pages/auth/login/bloc/login_bloc.dart';
import 'package:groupie_v2/pages/auth/login/login_page.dart';
import 'package:groupie_v2/pages/auth/register/bloc/register_bloc.dart';
import 'package:groupie_v2/pages/chat/bloc/chat_bloc.dart';
import 'package:groupie_v2/pages/home/home_page.dart';
import 'package:groupie_v2/services/auth_services.dart';
import 'package:groupie_v2/services/database_service.dart';
import 'package:groupie_v2/shared/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
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
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

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
        BlocProvider(create: (context) => RegisterBloc(authService: AuthService())),
        BlocProvider(create: (context) => LoginBloc(authService: AuthService())),
        BlocProvider(create: (context) => ChatBloc(databaseService: DatabaseService())),
      //  BlocProvider(create: (context) => HomeBloc(uid: userId)..add(FetchGroups())),
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
