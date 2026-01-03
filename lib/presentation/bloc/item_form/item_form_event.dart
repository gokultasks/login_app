import 'package:equatable/equatable.dart';

enum FormFieldKey {
  title,
  description,
  category,
  isActive,
  dueDate,
  estimatedHours,
  budget,
}

abstract class ItemFormEvent extends Equatable {
  const ItemFormEvent();

  @override
  List<Object?> get props => [];
}

class FormInitialized extends ItemFormEvent {
  final String? itemId;
  final Map<String, dynamic>? initialData;

  const FormInitialized({this.itemId, this.initialData});

  @override
  List<Object?> get props => [itemId, initialData];
}

class FieldChanged<T> extends ItemFormEvent {
  final FormFieldKey key;
  final T value;

  const FieldChanged(this.key, this.value);

  @override
  List<Object?> get props => [key, value];
}

class PartialSaveRequested extends ItemFormEvent {}

class SubmitRequested extends ItemFormEvent {
  final String userId;

  const SubmitRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class FormReset extends ItemFormEvent {}

// Legacy events for backward compatibility
class TitleChanged extends ItemFormEvent {
  final String title;

  const TitleChanged(this.title);

  @override
  List<Object?> get props => [title];
}

class DescriptionChanged extends ItemFormEvent {
  final String description;

  const DescriptionChanged(this.description);

  @override
  List<Object?> get props => [description];
}

class CategoryChanged extends ItemFormEvent {
  final String category;

  const CategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class IsActiveChanged extends ItemFormEvent {
  final bool isActive;

  const IsActiveChanged(this.isActive);

  @override
  List<Object?> get props => [isActive];
}

class FormSubmitted extends ItemFormEvent {
  final String userId;

  const FormSubmitted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateItem extends ItemFormEvent {
  final String itemId;

  const UpdateItem(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
