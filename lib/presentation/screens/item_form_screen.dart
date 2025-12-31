import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/item_form/item_form_bloc.dart';
import '../bloc/item_form/item_form_event.dart';
import '../bloc/item_form/item_form_state.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Technology',
    'Business',
    'Health',
    'Education',
    'Entertainment',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text(
          'Add New Item',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB74D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: BlocListener<ItemFormBloc, ItemFormState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, state.createdItem);
          } else if (state.status == FormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to add item'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_document,
                      size: 48,
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                BlocBuilder<ItemFormBloc, ItemFormState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Title',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.titleError != null
                                  ? Colors.red
                                  : const Color(0xFFFFB74D),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _titleController,
                            onChanged: (value) {
                              context.read<ItemFormBloc>().add(
                                TitleChanged(value),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter item title',
                              prefixIcon: const Icon(
                                Icons.title,
                                color: Color(0xFFFFB74D),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        if (state.titleError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              state.titleError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                BlocBuilder<ItemFormBloc, ItemFormState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.descriptionError != null
                                  ? Colors.red
                                  : const Color(0xFFFFB74D),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            onChanged: (value) {
                              context.read<ItemFormBloc>().add(
                                DescriptionChanged(value),
                              );
                            },
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter item description',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 60),
                                child: Icon(
                                  Icons.description,
                                  color: Color(0xFFFFB74D),
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        if (state.descriptionError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              state.descriptionError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                BlocBuilder<ItemFormBloc, ItemFormState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.categoryError != null
                                  ? Colors.red
                                  : const Color(0xFFFFB74D),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: state.category.isEmpty
                                ? null
                                : state.category,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.category,
                                color: Color(0xFFFFB74D),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            hint: Text(
                              'Select a category',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                context.read<ItemFormBloc>().add(
                                  CategoryChanged(value),
                                );
                              }
                            },
                          ),
                        ),
                        if (state.categoryError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              state.categoryError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                BlocBuilder<ItemFormBloc, ItemFormState>(
                  builder: (context, state) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFB74D),
                          width: 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: const Text(
                          'Mark this item as active',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: state.isActive,
                        activeColor: const Color(0xFFFFB74D),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<ItemFormBloc>().add(
                              IsActiveChanged(value),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                BlocBuilder<ItemFormBloc, ItemFormState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == FormStatus.submitting
                          ? null
                          : () {
                              context.read<ItemFormBloc>().add(
                                const FormSubmitted(),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB74D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: state.status == FormStatus.submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Add Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
