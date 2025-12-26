import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/AuthEvent/DeleteAccountEvent.dart';
import '../bloc/AuthState/auth_loading_state.dart';
import '../bloc/AuthState/auth_failure_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/AuthEvent/LogoutEvent.dart';
import '../bloc/AuthState/auth_state.dart';
import '../bloc/AuthState/Auth_initial_state.dart';
import 'LoginPage.dart';

class HomePage extends StatelessWidget {
  final String name;
  final String email;

  const HomePage({
    super.key,
    required this.name,
    required this.email,
  });

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Account"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(
                DeleteAccountEvent(email, password),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Profile"),
        backgroundColor: Colors.amber.shade300,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade300,
              Colors.amber.shade100,
              Colors.white,
            ],
          ),
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authinital) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Loginpage()),
                    (route) => false,
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
          child: BlocBuilder<AuthBloc, AuthState>(  // ✅ ADD THIS
            builder: (context, state) {  // ✅ ADD THIS
              final isLoading = state is AuthLoading;  // ✅ DEFINE HERE

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade200,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 60),

                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.amber.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade300,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                            context.read<AuthBloc>().add(LogoutEvent());
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: ElevatedButton.icon(
                          icon: isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                              : const Icon(Icons.delete_forever,
                              color: Colors.red),
                          label: Text(
                            isLoading ? "Deleting..." : "Delete Account",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                            _showDeleteAccountDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },  // ✅ CLOSE BlocBuilder
          ),  // ✅ CLOSE BlocBuilder
        ),
      ),
    );
  }
}