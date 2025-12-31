import 'package:equatable/equatable.dart';
import '../../../data/models/item_model.dart';

enum FormStatus { initial, submitting, success, failure }

class ItemFormState extends Equatable {
  final String title;
  final String description;
  final String category;
  final bool isActive;
  final FormStatus status;
  final String? errorMessage;
  final String? titleError;
  final String? descriptionError;
  final String? categoryError;
  final ItemModel? createdItem;

  const ItemFormState({
    this.title = '',
    this.description = '',
    this.category = '',
    this.isActive = true,
    this.status = FormStatus.initial,
    this.errorMessage,
    this.titleError,
    this.descriptionError,
    this.categoryError,
    this.createdItem,
  });

  bool get isValid =>
      title.isNotEmpty &&
      description.isNotEmpty &&
      category.isNotEmpty &&
      titleError == null &&
      descriptionError == null &&
      categoryError == null;

  ItemFormState copyWith({
    String? title,
    String? description,
    String? category,
    bool? isActive,
    FormStatus? status,
    String? errorMessage,
    String? titleError,
    String? descriptionError,
    String? categoryError,
    ItemModel? createdItem,
    bool clearTitleError = false,
    bool clearDescriptionError = false,
    bool clearCategoryError = false,
    bool clearErrors = false,
  }) {
    return ItemFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      titleError: (clearErrors || clearTitleError)
          ? null
          : (titleError ?? this.titleError),
      descriptionError: (clearErrors || clearDescriptionError)
          ? null
          : (descriptionError ?? this.descriptionError),
      categoryError: (clearErrors || clearCategoryError)
          ? null
          : (categoryError ?? this.categoryError),
      createdItem: createdItem ?? this.createdItem,
    );
  }

  @override
  List<Object?> get props => [
    title,
    description,
    category,
    isActive,
    status,
    errorMessage,
    titleError,
    descriptionError,
    categoryError,
    createdItem,
  ];
}
