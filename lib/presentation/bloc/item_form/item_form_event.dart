import 'package:equatable/equatable.dart';

abstract class ItemFormEvent extends Equatable {
  const ItemFormEvent();

  @override
  List<Object?> get props => [];
}

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
  const FormSubmitted();
}

class FormReset extends ItemFormEvent {
  const FormReset();
}
