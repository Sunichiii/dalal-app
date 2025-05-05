import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import '../../../../core/services/auth_services.dart';
import '../../../../core/services/database_service.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService authService;

  LoginBloc({required this.authService}) : super(LoginInitial()) {
    on<LoginUser>(_onLoginUser);
  }

  Future<void> _onLoginUser(LoginUser event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      bool result = await authService.loginWithEmailAndPassword(
        event.email, event.password,
      )as bool;

      if (result) {
        QuerySnapshot snapshot = await DatabaseService(
          uid: FirebaseAuth.instance.currentUser!.uid,
        ).gettingUserData(event.email);

        // Save bloc status
        await HelperFunctions.saveUserLoggedInStatus(true);
        await HelperFunctions.saveUserEmailSF(event.email);
        await HelperFunctions.saveUserNameSF(snapshot.docs[0]['fullName']);

        emit(LoginSuccess());
      } else {
        emit(LoginFailure(error: "Login failed. Check your credentials."));
      }
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }
}
