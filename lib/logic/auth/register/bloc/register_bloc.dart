import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/auth_services.dart';
import 'register_event.dart';
import 'register_state.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthService authService;

  RegisterBloc({required this.authService}) : super(RegisterInitial()) {
    on<RegisterUser>(_onRegisterUser);
  }

  Future<void> _onRegisterUser(RegisterUser event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      bool result = (await authService.registerUserWithEmailAndPassword(
        event.fullName, event.email, event.password,
      )) as bool;

      if (result) {
        await HelperFunctions.saveUserLoggedInStatus(true);
        await HelperFunctions.saveUserEmailSF(event.email);
        await HelperFunctions.saveUserNameSF(event.fullName);
        emit(RegisterSuccess());
      } else {
        emit(RegisterFailure(error: "Registration failed. Try again."));
      }
    } catch (e) {
      emit(RegisterFailure(error: e.toString()));
    }
  }
}
