import 'auth_state.dart';

class AuthSucess extends AuthState{
  final String email;
  final String name;
  AuthSucess(this.email,this.name);
}