import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/AuthEvent/LoginEvent.dart';
import '../bloc/AuthState/auth_state.dart';
import '../bloc/AuthState/auth_loading_state.dart';
import '../bloc/AuthState/auth_failure_state.dart';
import '../bloc/AuthState/auth_success_state.dart';

import 'Signup.dart';
import 'Home.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.amber.shade50,
              Colors.amber.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSucess) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      name: state.name,
                      email: state.email,
                    ),
                  ),
                );
              }

              if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              }
            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      size: 80,
                      color: Colors.amber.shade600,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // EMAIL FIELD
                    TextField(
                      controller: emailcontroller,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon:
                        Icon(Icons.email, color: Colors.amber.shade600),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD FIELD
                    TextField(
                      controller: passwordcontroller,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon:
                        Icon(Icons.lock, color: Colors.amber.shade600),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // LOGIN BUTTON / LOADER
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return CircularProgressIndicator(
                            color: Colors.amber.shade600,
                          );
                        }

                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                LoginEvent(
                                  emailcontroller.text.trim(),
                                  passwordcontroller.text.trim(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // SIGNUP NAVIGATION
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Don’t have an account? Sign up",
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
