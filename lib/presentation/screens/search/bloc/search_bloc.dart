import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:groupie_v2/presentation/screens/search/bloc/search_event.dart';
import 'package:groupie_v2/presentation/screens/search/bloc/search_state.dart';
import '../../../../core/services/database_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final DatabaseService db;

  SearchBloc({required this.db}) : super(SearchInitial()) {
    on<SearchGroups>(_onSearchGroups);
    on<SendJoinRequest>(_onSendJoinRequest);
  }

  Future<void> _onSearchGroups(SearchGroups event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      var result = await db.searchByName(event.query);
      emit(SearchLoaded(result));
    } catch (e) {
      emit(SearchError("Failed to search groups"));
    }
  }

  Future<void> _onSendJoinRequest(SendJoinRequest event, Emitter<SearchState> emit) async {
    try {
      await db.sendJoinRequest(event.groupId, event.userName, event.userId);
      emit(JoinRequestSent(event.groupName));
    } catch (e) {
      emit(SearchError("Failed to send join request"));
    }
  }
}
