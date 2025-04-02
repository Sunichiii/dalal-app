import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userName;
  final String email;
  final Stream<DocumentSnapshot> groupsStream;

  const HomeLoaded({
    required this.userName,
    required this.email,
    required this.groupsStream,
  });

  @override
  List<Object?> get props => [userName, email, groupsStream];
}

class GroupCreating extends HomeState {}

class GroupCreated extends HomeState {}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
