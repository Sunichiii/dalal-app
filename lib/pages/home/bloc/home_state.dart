import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Stream groups;
  HomeLoaded({required this.groups});

  @override
  List<Object?> get props => [groups];
}

class HomeError extends HomeState {
  final String errorMessage;
  HomeError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
