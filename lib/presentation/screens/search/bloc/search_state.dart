import 'package:cloud_firestore/cloud_firestore.dart';

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final QuerySnapshot results;
  SearchLoaded(this.results);
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

class JoinRequestSent extends SearchState {
  final String groupName;
  JoinRequestSent(this.groupName);
}
