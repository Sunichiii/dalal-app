import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import 'package:groupie_v2/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:groupie_v2/presentation/screens/home/bloc/home_bloc.dart';
import 'package:groupie_v2/presentation/screens/home/bloc/home_event.dart';
import 'package:groupie_v2/presentation/screens/home/home_page.dart';
import 'package:groupie_v2/presentation/screens/onboarding/onboarding_page.dart';
import 'package:groupie_v2/presentation/screens/search/bloc/search_bloc.dart';
import 'package:groupie_v2/core/services/auth_services.dart';
import 'package:groupie_v2/core/services/database_service.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/logic/auth/login/bloc/login_bloc.dart';
import 'package:groupie_v2/logic/auth/login/login_page.dart';
import 'package:groupie_v2/logic/auth/register/bloc/register_bloc.dart';

import 'core/services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Initialize notifications
  // NotificationService notificationService = NotificationService();
  // await notificationService.initializeNotifications();

  // Initialize Firebase
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
  bool _isOnboardingCompleted = false;
  bool _isLoading = true;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check onboarding status
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Check authentication status
      final authStatus = await HelperFunctions.getUserLoggedInStatus();
      if (authStatus != null) {
        setState(() {
          _isSignedIn = authStatus;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    setState(() {
      _isOnboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Constants().backGroundColor,
          body: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => RegisterBloc(authService: AuthService())),
        BlocProvider(create: (context) => LoginBloc(authService: AuthService())),
        BlocProvider(create: (context) => ChatBloc(databaseService: DatabaseService())),
        BlocProvider<SearchBloc>(create: (context) => SearchBloc(db: DatabaseService())),
        BlocProvider<HomeBloc>(create: (_) => HomeBloc()..add(LoadUserData())),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'Nunito',
          primaryColor: Constants().primaryColor,
          scaffoldBackgroundColor: Constants().backGroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: Constants().backGroundColor,
            elevation: 0,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: _isOnboardingCompleted
            ? (_isSignedIn ? HomePage() : LoginPage())
            : OnboardingPage(onCompleted: _completeOnboarding),
      ),
    );
  }
}