import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import '../../../../core/services/auth_services.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthService authService;

  ProfileBloc({required this.authService}) : super(ProfileInitial()) {
    on<FetchProfileData>(_onFetchProfileData);
    on<LogoutUser>(_onLogoutUser);
  }

  // Fetch user profile data
  Future<void> _onFetchProfileData(
      FetchProfileData event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());

    try {
      String? userName = await HelperFunctions.getUserNameSF();
      String? email = await HelperFunctions.getUserEmailSF();

      if (userName != null && email != null) {
        emit(ProfileLoaded(userName: userName, email: email));
      } else {
        emit(ProfileError(message: "Failed to fetch user data"));
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  // Handle Logout
  Future<void> _onLogoutUser(LogoutUser event, Emitter<ProfileState> emit) async {
    try {
      await authService.signOut();
      emit(ProfileLoggedOut());
    } catch (e) {
      emit(ProfileError(message: "Logout failed. Please try again."));
    }
  }
}
