import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final String email;
  final String password;
  final String confirmpassword;
  final String name;
  final bool isValid;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;
  final bool isSignupMode;

  const AuthState({
    this.email = '',
    this.password = '',
    this.confirmpassword='',
    this.name = '',
    this.isValid = false,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
    this.isSignupMode=false

  });

  AuthState copyWith({
    String? email,
    String? password,
    String? confirmpassword,
    String? name,
    bool? isValid,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    bool? isSignupMode,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmpassword: confirmpassword ?? this.confirmpassword,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error,
      isSignupMode: isSignupMode ?? this.isSignupMode,
    );
  }

  @override
  List<Object?> get props =>
      [email, password, confirmpassword,name, isValid, isLoading, isLoggedIn, error,isSignupMode];
}
