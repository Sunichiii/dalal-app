import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchGroups extends HomeEvent {}

class CreateGroup extends HomeEvent {
  final String userName;
  final String groupName;

  CreateGroup({required this.userName, required this.groupName});

  @override
  List<Object?> get props => [userName, groupName];
}
