import 'AuthEvent.dart';

class DeleteAccountEvent extends AuthEvent {
  final String email;
  final String password;

  DeleteAccountEvent(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}