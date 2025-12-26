import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_app/ui/widgets/InputBoxStyle.dart';

import '../bloc/AuthEvent/AuthSetEvent.dart';
import '../bloc/AuthEvent/ResetEvent.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/AuthEvent/AuthEvent.dart';
import '../bloc/AuthEvent/SignupEvent.dart';
import '../bloc/AuthState/auth_state.dart';
import '../bloc/AuthState/auth_loading_state.dart';
import '../bloc/AuthState/auth_failure_state.dart';
import '../bloc/AuthState/auth_success_state.dart';
import 'widgets/app_button.dart';
import 'Home.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(SetSignupMode(true));

    emailController.addListener(() {
      context.read<AuthBloc>().add(EmailChanged(emailController.text.trim()));
    });

    passwordController.addListener(() {
      context.read<AuthBloc>().add(PasswordChanged(passwordController.text.trim()));
    });

    confirmPasswordController.addListener(() {
      context.read<AuthBloc>().add(ConfirmPasswordChanged(confirmPasswordController.text.trim()));
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

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
                Future.delayed(const Duration(milliseconds: 100), () {
                  context.read<AuthBloc>().add(EmailChanged(emailController.text.trim()));
                });
              }

            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 80,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign up to get started",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    InputStyle(nameController: nameController,label: "Name",),
                    const SizedBox(height: 16),
                    InputStyle(nameController: emailController,label: "Email",),
                    const SizedBox(height: 16),
                    InputStyle(nameController: passwordController,label: "Password"),
                    const SizedBox(height: 16),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final passwordsMatch = state.password.isNotEmpty &&
                            state.confirmpassword.isNotEmpty &&
                            state.password == state.confirmpassword;
                        final showError = state.confirmpassword.isNotEmpty &&
                            !passwordsMatch;

                        return TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.amber.shade600),
                            suffixIcon: state.confirmpassword.isNotEmpty
                                ? Icon(
                              passwordsMatch ? Icons.check_circle : Icons.error,
                              color: passwordsMatch ? Colors.green : Colors.red,
                            )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: showError ? Colors.red.shade300 : Colors.amber.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: showError ? Colors.red : Colors.amber.shade600,
                                width: 2,
                              ),
                            ),
                            errorText: showError ? "Passwords do not match" : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
final isEnabled = state is! AuthLoading &&
    state.isValid &&
    nameController.text.trim().isNotEmpty;

                        return AppButton(
                          text: "Create Account",
                          isLoading: state is AuthLoading,
                          onPressed: isEnabled ? () {
                            context.read<AuthBloc>().add(
                              SignupEvent(
                                nameController.text.trim(),
                                emailController.text.trim(),
                                passwordController.text.trim(),
                                confirmPasswordController.text.trim(),
                              ),
                            );
                          } : null,
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Already have an account? Login",
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