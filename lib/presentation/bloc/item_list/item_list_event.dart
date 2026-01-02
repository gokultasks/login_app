import 'package:equatable/equatable.dart';
import '../../../data/models/item_model.dart';

abstract class ItemListEvent extends Equatable {
  const ItemListEvent();

  @override
  List<Object?> get props => [];
}

class LoadItems extends ItemListEvent {
  final String userId;

  const LoadItems(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadMoreItems extends ItemListEvent {
  final String userId;

  const LoadMoreItems(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshItems extends ItemListEvent {
  final String userId;

  const RefreshItems(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddNewItem extends ItemListEvent {
  final ItemModel item;

  const AddNewItem(this.item);

  @override
  List<Object?> get props => [item];
}

class FilterItems extends ItemListEvent {
  final String userId;
  final String? category;
  final bool? isActive;

  const FilterItems({
    required this.userId,
    this.category,
    this.isActive,
  });

  @override
  List<Object?> get props => [userId, category, isActive];
}

class ClearFilters extends ItemListEvent {
  final String userId;

  const ClearFilters(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DeleteItem extends ItemListEvent {
  final String itemId;

  const DeleteItem(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
