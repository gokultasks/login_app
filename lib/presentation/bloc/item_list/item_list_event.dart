import 'package:equatable/equatable.dart';
import '../../../data/models/item_model.dart';

abstract class ItemListEvent extends Equatable {
  const ItemListEvent();

  @override
  List<Object?> get props => [];
}

class LoadItems extends ItemListEvent {
  const LoadItems();
}

class LoadMoreItems extends ItemListEvent {
  const LoadMoreItems();
}

class RefreshItems extends ItemListEvent {
  const RefreshItems();
}

class AddNewItem extends ItemListEvent {
  final ItemModel item;

  const AddNewItem(this.item);

  @override
  List<Object?> get props => [item];
}
