import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_app/bloc/AuthEvent/LoginEvent.dart';

import 'AuthEvent/AuthEvent.dart';
import 'AuthEvent/AuthSetEvent.dart';
import 'AuthEvent/DeleteAccountEvent.dart';
import 'AuthEvent/LogoutEvent.dart';
import 'AuthEvent/ResetEvent.dart';
import 'AuthEvent/SignupEvent.dart';

import 'AuthState/auth_state.dart';
import 'AuthState/Auth_initial_state.dart';
import 'AuthState/auth_loading_state.dart';
import 'AuthState/auth_failure_state.dart';
import 'AuthState/auth_success_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _usersKey = 'users_data';

  AuthBloc() : super(const AuthState()) {
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<LoginEvent>(_onLogin);
    on<SignupEvent>(_onSignup);
    on<LogoutEvent>(_onLogout);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<ResetEvent>(_onReset);
    on<SetSignupMode>((event, emit) {
      emit(state.copyWith(isSignupMode: event.isSignupMode, isValid: false));
    });
  }
  Future<void> _deleteUser(String email) async {
    final users = await _loadUsers();
    users.remove(email);
    await _saveUsers(users);
  }
  void _onReset(ResetEvent event, Emitter<AuthState> emit) {
    emit(const AuthState());
  }



  void _onDeleteAccount(DeleteAccountEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    await Future.delayed(const Duration(milliseconds: 500));

    final user = await _getUser(event.email);

    if (user == null) {
      emit(AuthFailure("Account not found"));
      return;
    }

    if (user["password"] != event.password) {
      emit(AuthFailure("Incorrect password"));
      return;
    }

    await _deleteUser(event.email);

    await _clearSession();

    emit(Authinital());
  }



  Future<void> _saveUsers(Map<String, Map<String, String>> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users);
    await prefs.setString(_usersKey, usersJson);
  }

  Future<Map<String, Map<String, String>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null || usersJson.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
      return decoded.map(
            (key, value) => MapEntry(
          key,
          Map<String, String>.from(value as Map),
        ),
      );
    } catch (e) {
      return {};
    }
  }

  Future<bool> _userExists(String email) async {
    final users = await _loadUsers();
    return users.containsKey(email);
  }

  Future<Map<String, String>?> _getUser(String email) async {
    final users = await _loadUsers();
    return users[email];
  }

  Future<void> _saveUser(String email, String name, String password) async {
    final users = await _loadUsers();
    users[email] = {
      "name": name,
      "password": password,
    };
    await _saveUsers(users);
  }

  Future<void> _saveSession(String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_email', email);
    await prefs.setString('current_user_name', name);
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_name');
    await prefs.setBool('is_logged_in', false);
  }

  Future<Map<String, String>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      return null;
    }

    final email = prefs.getString('current_user_email');
    final name = prefs.getString('current_user_name');

    if (email != null && name != null) {
      return {'email': email, 'name': name};
    }

    return null;
  }
  void _onConfirmPasswordChanged(ConfirmPasswordChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        confirmpassword: event.confirmPassword,
        isValid: _validateSignup(state.email, state.password, event.confirmPassword),
        error: null,
      ),
    );
  }

  void _onEmailChanged(EmailChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        email: event.email,
        isValid: state.isSignupMode
            ? _validateSignup(event.email, state.password, state.confirmpassword)
            : _validateLogin(event.email, state.password),
        error: null,
      ),
    );
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        password: event.password,
        isValid: state.isSignupMode
            ? _validateSignup(state.email, event.password, state.confirmpassword)
            : _validateLogin(state.email, event.password),
        error: null,
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 5;
  }

  bool _validateSignup(String email, String password, String confirmPassword) {
    return _isValidEmail(email) &&
        _isValidPassword(password) &&
        password == confirmPassword &&
        password.isNotEmpty;
  }
  void _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    if (!_validateLogin(event.email, event.password)) {
      emit(AuthFailure("Please enter valid email and password"));
      return;
    }

    emit(AuthLoading());

    await Future.delayed(const Duration(seconds: 1));

    final user = await _getUser(event.email);

    if (user == null || user["password"] != event.password) {
      emit(AuthFailure("Invalid email or password"));
      return;
    }

    await _saveSession(event.email, user["name"]!);

    emit(AuthSucess(
      user["name"]!,
      event.email,
    ));
  }

  void _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    if (!_isValidEmail(event.email)) {
      emit(AuthFailure("Please enter a valid email"));
      return;
    }

    if (!_isValidPassword(event.password)) {
      emit(AuthFailure("Password must be at least 5 characters"));
      return;
    }

    if (event.password != event.conformpassword) {
      emit(AuthFailure("Passwords do not match"));
      return;
    }

    emit(AuthLoading());

    await Future.delayed(const Duration(seconds: 1));

    final userExists = await _userExists(event.email);

    if (userExists) {
      emit(AuthFailure("User already exists"));
      return;
    } else {
      await _saveUser(event.email, event.name, event.password);
      await _saveSession(event.email, event.name);

      emit(AuthSucess(
        event.name,
        event.email,
      ));
    }
  }

  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) async{
    await _clearSession();
    emit(Authinital());
  }

  bool _validateLogin(String email, String password) {
    return _isValidEmail(email) && _isValidPassword(password);
  }
}

