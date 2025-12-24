import 'package:flutter/material.dart';
import 'AuthEvent.dart';

class SignupEvent extends AuthEvent{
  final String name;
  final String email;
  final String password;

  SignupEvent(this.name, this.email, this.password);

}