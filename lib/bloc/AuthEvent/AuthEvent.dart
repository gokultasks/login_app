import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EmailChanged extends AuthEvent {
  final String email;
  EmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class ConfirmPasswordChanged extends AuthEvent {
  final String confirmPassword;
  ConfirmPasswordChanged(this.confirmPassword);

  @override
  List<Object?> get props => [confirmPassword];
}
class PasswordChanged extends AuthEvent {
  final String password;
  PasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class LoginSubmitted extends AuthEvent {}

class SignupSubmitted extends AuthEvent {
  final String name;
  SignupSubmitted(this.name);

  @override
  List<Object?> get props => [name];
}

class LogoutRequested extends AuthEvent {}
