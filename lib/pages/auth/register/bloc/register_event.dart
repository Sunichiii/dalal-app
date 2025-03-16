import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class RegisterUser extends RegisterEvent {
  final String fullName;
  final String email;
  final String password;

  RegisterUser({required this.fullName, required this.email, required this.password});

  @override
  List<Object> get props => [fullName, email, password];
}
