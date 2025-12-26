
import 'AuthEvent.dart';

class SetSignupMode extends AuthEvent {
  final bool isSignupMode;
  SetSignupMode(this.isSignupMode);
}