import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputStyle extends StatelessWidget {
  const InputStyle({
    super.key,
    required this.nameController,
    required this.label
  });

  final TextEditingController nameController;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: nameController,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.person, color: Colors.amber.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber.shade600, width: 2),
        ),
      ),
    );
  }
}
