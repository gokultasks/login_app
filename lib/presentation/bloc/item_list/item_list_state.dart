import 'package:equatable/equatable.dart';
import '../../../data/models/item_model.dart';

enum ItemListStatus { initial, loading, success, failure, loadingMore }

class ItemListState extends Equatable {
  final ItemListStatus status;
  final List<ItemModel> items;
  final bool hasReachedMax;
  final String? errorMessage;
  final int currentPage;

  const ItemListState({
    this.status = ItemListStatus.initial,
    this.items = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.currentPage = 0,
  });

  ItemListState copyWith({
    ItemListStatus? status,
    List<ItemModel>? items,
    bool? hasReachedMax,
    String? errorMessage,
    int? currentPage,
  }) {
    return ItemListState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    hasReachedMax,
    errorMessage,
    currentPage,
  ];
}
