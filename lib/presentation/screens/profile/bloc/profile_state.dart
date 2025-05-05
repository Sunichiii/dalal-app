import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Initial state
class ProfileInitial extends ProfileState {}

// Loading state
class ProfileLoading extends ProfileState {}

// Loaded state with user data
class ProfileLoaded extends ProfileState {
  final String userName;
  final String email;

  ProfileLoaded({required this.userName, required this.email});

  @override
  List<Object?> get props => [userName, email];
}

// Logout state
class ProfileLoggedOut extends ProfileState {}

// Error state
class ProfileError extends ProfileState {
  final String message;

  ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
