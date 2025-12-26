import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_app/ui/AuthCheckPage.dart';

import 'bloc/auth_bloc.dart';
import 'ui/LoginPage.dart';

void main() {
  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheckPage(),
    );
  }
}
