import 'package:equatable/equatable.dart';
import 'item_form_event.dart';
import '../../../data/models/item_model.dart';

enum FormStatus { initial, loading, success, failure }

enum ValidationStatus { valid, invalid, pending }

class ItemFormState extends Equatable {
  final String? itemId;  
  final String title;
  final String description;
  final String category;
  final bool isActive;
  final DateTime? dueDate;
  final double? estimatedHours;
  final double? budget;
  
  final Map<FormFieldKey, String?> errors;
  final FormStatus status;
  final ValidationStatus validationStatus;
  final String? globalError;
  final bool isDraftLoaded;
  final ItemModel? createdItem;

  const ItemFormState({
    this.itemId,
    this.title = '',
    this.description = '',
    this.category = '',
    this.isActive = true,
    this.dueDate,
    this.estimatedHours,
    this.budget,
    this.errors = const {},
    this.status = FormStatus.initial,
    this.validationStatus = ValidationStatus.pending,
    this.globalError,
    this.isDraftLoaded = false,
    this.createdItem,
  });

  bool get isValid {
    return errors.values.every((error) => error == null) &&
        validationStatus == ValidationStatus.valid;
  }

  bool get shouldShowDueDate => isActive;

  bool get shouldShowBusinessFields => category == 'Business';

  bool get shouldShowBudget => category == 'Business' && isActive;

  ItemFormState copyWith({
    String? itemId,
    String? title,
    String? description,
    String? category,
    bool? isActive,
    DateTime? dueDate,
    double? estimatedHours,
    double? budget,
    Map<FormFieldKey, String?>? errors,
    FormStatus? status,
    ValidationStatus? validationStatus,
    String? globalError,
    bool? isDraftLoaded,
    ItemModel? createdItem,
    bool clearDueDate = false,
    bool clearEstimatedHours = false,
    bool clearBudget = false,
    bool clearGlobalError = false,
  }) {
    return ItemFormState(
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      estimatedHours: clearEstimatedHours ? null : (estimatedHours ?? this.estimatedHours),
      budget: clearBudget ? null : (budget ?? this.budget),
      errors: errors ?? this.errors,
      status: status ?? this.status,
      validationStatus: validationStatus ?? this.validationStatus,
      globalError: clearGlobalError ? null : (globalError ?? this.globalError),
      isDraftLoaded: isDraftLoaded ?? this.isDraftLoaded,
      createdItem: createdItem ?? this.createdItem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'isActive': isActive,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      if (budget != null) 'budget': budget,
    };
  }

  factory ItemFormState.fromJson(Map<String, dynamic> json) {
    return ItemFormState(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      estimatedHours: json['estimatedHours'] != null
          ? (json['estimatedHours'] as num).toDouble()
          : null,
      budget: json['budget'] != null
          ? (json['budget'] as num).toDouble()
          : null,
    );
  }

  @override
  List<Object?> get props => [
        itemId,
        title,
        description,
        category,
        isActive,
        dueDate,
        estimatedHours,
        budget,
        errors,
        status,
        validationStatus,
        globalError,
        isDraftLoaded,
        createdItem,
      ];
}
