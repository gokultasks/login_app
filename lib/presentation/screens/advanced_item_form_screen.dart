import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/item_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/item_form/item_form_bloc.dart';
import '../bloc/item_form/item_form_event.dart';
import '../bloc/item_form/item_form_state.dart';

class AdvancedItemFormScreen extends StatefulWidget {
  final ItemModel? item;
  
  const AdvancedItemFormScreen({super.key, this.item});

  @override
  State<AdvancedItemFormScreen> createState() => _AdvancedItemFormScreenState();
}

class _AdvancedItemFormScreenState extends State<AdvancedItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _draftMessageShown = false;
  bool _successMessageShown = false;
  bool _errorMessageShown = false;

  final List<String> _categories = [
    'Technology',
    'Business',
    'Health',
    'Education',
    'Entertainment',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize form with item data if editing, otherwise load draft
    if (widget.item != null) {
      final item = widget.item!;
      context.read<ItemFormBloc>().add(
        FormInitialized(
          itemId: item.id,
          initialData: {
            'title': item.title,
            'description': item.description,
            'category': item.category,
            'isActive': item.isActive,
            if (item.dueDate != null) 'dueDate': item.dueDate!.toIso8601String(),
            if (item.estimatedHours != null) 'estimatedHours': item.estimatedHours,
            if (item.budget != null) 'budget': item.budget,
          },
        ),
      );
    } else {
      // Load draft if exists for new items
      context.read<ItemFormBloc>().add(const FormInitialized());
    }
    
    // Auto-save every 30 seconds
    Future.delayed(const Duration(seconds: 30), _autoSaveDraft);
  }

  void _autoSaveDraft() {
    if (mounted) {
      context.read<ItemFormBloc>().add(PartialSaveRequested());
      Future.delayed(const Duration(seconds: 30), _autoSaveDraft);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _updateControllersFromState(ItemFormState state) {
    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.text = state.description;
    }
    if (state.estimatedHours != null) {
      final hoursText = state.estimatedHours.toString();
      if (_estimatedHoursController.text != hoursText) {
        _estimatedHoursController.text = hoursText;
      }
    }
    if (state.budget != null) {
      final budgetText = state.budget.toString();
      if (_budgetController.text != budgetText) {
        _budgetController.text = budgetText;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item != null ? 'Edit Item' : 'Add New Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: () {
              context.read<ItemFormBloc>().add(PartialSaveRequested());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: () {
              context.read<ItemFormBloc>().add(FormReset());
              _titleController.clear();
              _descriptionController.clear();
              _estimatedHoursController.clear();
              _budgetController.clear();
            },
          ),
        ],
      ),
      body: BlocConsumer<ItemFormBloc, ItemFormState>(
        listener: (context, state) {
          // Update controllers when state changes (e.g., draft loaded or editing)
          _updateControllersFromState(state);
          
          if (state.isDraftLoaded && !_draftMessageShown) {
            _draftMessageShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Draft loaded')),
            );
          }

          if (state.status == FormStatus.success && !_successMessageShown) {
            _successMessageShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.item != null 
                    ? 'Item updated successfully!' 
                    : 'Item created successfully!'),
              ),
            );
            Navigator.pop(context, state.createdItem);
          }

          if (state.status == FormStatus.failure && state.globalError != null && !_errorMessageShown) {
            _errorMessageShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.globalError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Draft indicator
                if (state.isDraftLoaded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Draft loaded. Continue where you left off.',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Global error message
                if (state.globalError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.globalError!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Title field
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Enter item title',
                  fieldKey: FormFieldKey.title,
                  maxLength: 50,
                  onChanged: (value) {
                    context.read<ItemFormBloc>().add(
                          FieldChanged<String>(FormFieldKey.title, value),
                        );
                  },
                  errorText: state.errors[FormFieldKey.title],
                ),

                const SizedBox(height: 16),

                // Description field
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Minimum 30 characters OR attach files',
                  fieldKey: FormFieldKey.description,
                  maxLines: 4,
                  maxLength: 200,
                  onChanged: (value) {
                    context.read<ItemFormBloc>().add(
                          FieldChanged<String>(FormFieldKey.description, value),
                        );
                  },
                  errorText: state.errors[FormFieldKey.description],
                ),

                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: state.category.isEmpty ? null : state.category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: const OutlineInputBorder(),
                    errorText: state.errors[FormFieldKey.category],
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
                            FieldChanged<String>(FormFieldKey.category, value),
                          );
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Active checkbox
                SwitchListTile(
                  title: const Text('Active Item'),
                  subtitle: const Text('Due date required when active'),
                  value: state.isActive,
                  onChanged: (value) {
                    context.read<ItemFormBloc>().add(
                          FieldChanged<bool>(FormFieldKey.isActive, value),
                        );
                  },
                ),

                const SizedBox(height: 16),

                // Conditional: Due Date (shown when isActive)
                if (state.shouldShowDueDate) ...[
                  _buildDateField(
                    label: 'Due Date',
                    hint: 'Select due date',
                    value: state.dueDate,
                    errorText: state.errors[FormFieldKey.dueDate],
                    onChanged: (date) {
                      context.read<ItemFormBloc>().add(
                            FieldChanged<DateTime?>(FormFieldKey.dueDate, date),
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Conditional: Business fields (shown when category = Business)
                if (state.shouldShowBusinessFields) ...[
                  Text(
                    'Business Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  // Estimated Hours
                  _buildNumberField(
                    controller: _estimatedHoursController,
                    label: 'Estimated Hours',
                    hint: 'Enter hours',
                    errorText: state.errors[FormFieldKey.estimatedHours],
                    onChanged: (value) {
                      final hours = double.tryParse(value);
                      context.read<ItemFormBloc>().add(
                            FieldChanged<double?>(
                                FormFieldKey.estimatedHours, hours),
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Conditional: Budget (shown when Business AND Active)
                if (state.shouldShowBudget) ...[
                  _buildNumberField(
                    controller: _budgetController,
                    label: 'Budget (\$)',
                    hint: 'Enter budget',
                    errorText: state.errors[FormFieldKey.budget],
                    prefix: const Text('\$ '),
                    onChanged: (value) {
                      final budget = double.tryParse(value);
                      context.read<ItemFormBloc>().add(
                            FieldChanged<double?>(FormFieldKey.budget, budget),
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 32),

                // Submit button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final userId = authState is AuthenticatedState
                        ? authState.user.id
                        : '';

                    return ElevatedButton(
                      onPressed: state.status == FormStatus.loading
                          ? null
                          : () {
                              context.read<ItemFormBloc>().add(
                                    SubmitRequested(userId),
                                  );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: state.status == FormStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.item != null ? 'Update Item' : 'Create Item'),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Validation status indicator
                if (state.validationStatus == ValidationStatus.valid)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'All fields are valid',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FormFieldKey fieldKey,
    required Function(String) onChanged,
    String? errorText,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        errorText: errorText,
        errorMaxLines: 2,
        counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
      ),
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    String? errorText,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        errorText: errorText,
        prefixText: prefix != null ? null : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required DateTime? value,
    required Function(DateTime?) onChanged,
    String? errorText,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? dateFormat.format(value) : hint,
          style: TextStyle(
            color: value != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
}
