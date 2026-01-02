import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/item_model.dart';

enum ItemListStatus { initial, loading, success, failure, loadingMore }

class ItemListState extends Equatable {
  final ItemListStatus status;
  final List<ItemModel> items;
  final bool hasReachedMax;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;
  final String? categoryFilter;
  final bool? isActiveFilter;

  const ItemListState({
    this.status = ItemListStatus.initial,
    this.items = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.lastDocument,
    this.categoryFilter,
    this.isActiveFilter,
  });

  ItemListState copyWith({
    ItemListStatus? status,
    List<ItemModel>? items,
    bool? hasReachedMax,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
    Object? categoryFilter = _undefined,
    Object? isActiveFilter = _undefined,
    bool clearFilters = false,
  }) {
    return ItemListState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      lastDocument: lastDocument ?? this.lastDocument,
      categoryFilter: clearFilters 
          ? null 
          : (categoryFilter == _undefined ? this.categoryFilter : categoryFilter as String?),
      isActiveFilter: clearFilters 
          ? null 
          : (isActiveFilter == _undefined ? this.isActiveFilter : isActiveFilter as bool?),
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        hasReachedMax,
        errorMessage,
        lastDocument,
        categoryFilter,
        isActiveFilter,
      ];
}

const Object _undefined = Object();
