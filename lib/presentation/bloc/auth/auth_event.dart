import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}


class CheckSessionEvent extends AuthEvent {}


class SignUpRequestedEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? profileImagePath;

  const SignUpRequestedEvent({
    required this.email,
    required this.password,
    required this.name,
    this.profileImagePath,
  });

  @override
  List<Object?> get props => [email, password, name, profileImagePath];
}


class OtpVerificationRequestedEvent extends AuthEvent {
  final String email;
  final String otp;
  final bool isSignUp;

  const OtpVerificationRequestedEvent({
    required this.email,
    required this.otp,
    required this.isSignUp,
  });

  @override
  List<Object?> get props => [email, otp, isSignUp];
}


class SendOtpEvent extends AuthEvent {
  final String email;

  const SendOtpEvent(this.email);

  @override
  List<Object?> get props => [email];
}


class SignInRequestedEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInRequestedEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}


class ForgotPasswordRequestedEvent extends AuthEvent {
  final String email;

  const ForgotPasswordRequestedEvent({required this.email});

  @override
  List<Object?> get props => [email];
}


class SignOutRequestedEvent extends AuthEvent {}


class DeleteAccountRequestedEvent extends AuthEvent {
  final String userId;

  const DeleteAccountRequestedEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}


class UpdateProfileEvent extends AuthEvent {
  final String userId;
  final String? name;
  final String? profileImagePath;

  const UpdateProfileEvent({
    required this.userId,
    this.name,
    this.profileImagePath,
  });

  @override
  List<Object?> get props => [userId, name, profileImagePath];
}
