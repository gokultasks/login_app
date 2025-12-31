import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}


class AuthInitialState extends AuthState {}


class AuthLoadingState extends AuthState {}


class AuthenticatedState extends AuthState {
  final UserModel user;

  const AuthenticatedState(this.user);

  @override
  List<Object?> get props => [user];
}


class UnauthenticatedState extends AuthState {}


class OtpSentState extends AuthState {
  final String email;
  final bool isSignUp;

  const OtpSentState({required this.email, required this.isSignUp});

  @override
  List<Object?> get props => [email, isSignUp];
}


class OtpVerifiedState extends AuthState {
  final String email;
  final bool isSignUp;

  const OtpVerifiedState({required this.email, required this.isSignUp});

  @override
  List<Object?> get props => [email, isSignUp];
}


class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}


class AuthSuccessState extends AuthState {
  final String message;

  const AuthSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}
