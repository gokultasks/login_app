import 'package:flutter/material.dart';
import 'AuthEvent.dart';

class LoginEvent extends AuthEvent{
  final String email;
  final String password;


  LoginEvent(this.email,this.password);
}

