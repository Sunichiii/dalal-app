import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

// Load user name, email, and group stream
class LoadUserData extends HomeEvent {}

// Create a new group
class CreateGroup extends HomeEvent {
  final String groupName;
  final String userId;
  final String userName;

  const CreateGroup({
    required this.groupName,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [groupName, userId, userName];
}
