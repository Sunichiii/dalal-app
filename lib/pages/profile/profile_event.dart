import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Fetch profile data (name & email)
class FetchProfileData extends ProfileEvent {}

// Logout user
class LogoutUser extends ProfileEvent {}
