import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_app/bloc/AuthEvent/LoginEvent.dart';
import 'package:login_app/bloc/AuthState/Auth_initial_state.dart';

import 'AuthEvent/AuthEvent.dart';
import 'AuthEvent/LogoutEvent.dart';
import 'AuthEvent/SignupEvent.dart';
import 'AuthEvent/LogoutEvent.dart';

import 'AuthState/auth_state.dart';
import 'AuthState/Auth_initial_state.dart';
import 'AuthState/auth_loading_state.dart';
import 'AuthState/auth_failure_state.dart';
import 'AuthState/auth_success_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Map<String, Map<String, String>> _users = {};

  AuthBloc() : super(Authinital()) {
    on<LoginEvent>(_onLogin);
    on<SignupEvent>(_onSignup);
    on<LogoutEvent>(_onLogout);
  }


  bool _isValidEmail(String email) {
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 5;
  }


  void _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    print('DEBUG: Login attempt with email: "${event.email}"');
    print('DEBUG: Email length: ${event.email.length}');
    print('DEBUG: Email is valid: ${_isValidEmail(event.email)}');
    
    if (!_isValidEmail(event.email)) {
      emit(AuthFailure("Please enter a valid email"));
      return;
    }

    if (!_isValidPassword(event.password)) {
      emit(AuthFailure("Password must be at least 5 characters"));
      return;
    }

    emit(AuthLoading());

    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(event.email) &&
        _users[event.email]!["password"] == event.password) {
      emit(AuthSucess(
        _users[event.email]!["name"]!,
        event.email,
      ));
    } else {
      emit(AuthFailure("Invalid email or password"));
    }
  }


  void _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    print('DEBUG SIGNUP: Email entered: "${event.email}"');
    print('DEBUG SIGNUP: Email length: ${event.email.length}');
    print('DEBUG SIGNUP: Email is valid: ${_isValidEmail(event.email)}');
    
    if (!_isValidEmail(event.email)) {
      emit(AuthFailure("Please enter a valid email"));
      return;
    }

    if (!_isValidPassword(event.password)) {
      emit(AuthFailure("Password must be at least 5 characters"));
      return;
    }

    emit(AuthLoading());

    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(event.email)) {
      emit(AuthFailure("User already exists"));
    } else {
      _users[event.email] = {
        "name": event.name,
        "password": event.password,
      };

      emit(AuthSucess(
        event.name,
        event.email,
      ));
    }
  }


  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) {
    emit(Authinital());
  }
}
