import 'package:flutter/material.dart';
import 'AuthEvent.dart';

class SignupEvent extends AuthEvent{
  final String name;
  final String email;
  final String password;
  final String conformpassword;

  SignupEvent(this.name, this.email, this.password,this.conformpassword);

}