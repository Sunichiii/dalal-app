import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:groupie_v2/core/services/database_service.dart';
import 'package:groupie_v2/data/sources/helper_function.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  HomeBloc() : super(HomeInitial()) {
    on<LoadUserData>(_onLoadUserData);
    on<CreateGroup>(_onCreateGroup);
  }

  Future<void> _onLoadUserData(
      LoadUserData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final String? email = await HelperFunctions.getUserEmailSF();
      final String? name = await HelperFunctions.getUserNameSF();
      final user = _auth.currentUser;

      if (email != null && name != null && user != null) {
        final stream = DatabaseService(uid: user.uid).getUserGroups();
        emit(HomeLoaded(userName: name, email: email, groupsStream: stream));
      } else {
        emit(const HomeError("Failed to load user info."));
      }
    } catch (e) {
      emit(HomeError("Something went wrong: $e"));
    }
  }

  Future<void> _onCreateGroup(
      CreateGroup event, Emitter<HomeState> emit) async {
    emit(GroupCreating());
    try {
      await DatabaseService(uid: event.userId).createGroup(
        event.userName,
        event.userId,
        event.groupName,
      );
      emit(GroupCreated());

      // Optionally reload user data to refresh group list
      add(LoadUserData());
    } catch (e) {
      emit(HomeError("Failed to create group: $e"));
    }
  }
}
