// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:groupie_v2/services/database_service.dart';
// import 'home_event.dart';
// import 'home_state.dart';
//
// class HomeBloc extends Bloc<HomeEvent, HomeState> {
//   final String uid;
//
//   HomeBloc({required this.uid}) : super(HomeInitial()) {
//     on<FetchGroups>(_onFetchGroups);
//     on<CreateGroup>(_onCreateGroup);
//   }
//
//   Future<void> _onFetchGroups(FetchGroups event, Emitter<HomeState> emit) async {
//     emit(HomeLoading());
//     try {
//       Stream groupsStream = DatabaseService(uid: uid).getUserGroup();
//       emit(HomeLoaded(groups: groupsStream));
//     } catch (e) {
//       emit(HomeError(errorMessage: "Failed to fetch groups: ${e.toString()}"));
//     }
//   }
//
//   Future<void> _onCreateGroup(CreateGroup event, Emitter<HomeState> emit) async {
//     try {
//       await DatabaseService(uid: uid).createGroup(event.userName, uid, event.groupName);
//       add(FetchGroups());
//     } catch (e) {
//       emit(HomeError(errorMessage: "Failed to create group: ${e.toString()}"));
//     }
//   }
// }
