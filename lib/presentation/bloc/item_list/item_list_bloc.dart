import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/services/sync_service.dart';
import 'item_list_event.dart';
import 'item_list_state.dart';

class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  final ItemRepository itemRepository;
  final SyncService? syncService;
  static const int pageSize = 15;

  ItemListBloc({
    required this.itemRepository,
    this.syncService,
  }) : super(const ItemListState()) {
    on<LoadItems>(_onLoadItems);
    on<LoadMoreItems>(_onLoadMoreItems);
    on<RefreshItems>(_onRefreshItems);
    on<AddNewItem>(_onAddNewItem);
    on<FilterItems>(_onFilterItems);
    on<ClearFilters>(_onClearFilters);
    on<DeleteItem>(_onDeleteItem);
  }

  Future<void> _onLoadItems(
    LoadItems event,
    Emitter<ItemListState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemListStatus.loading));

      // Sync pending operations before fetching
      if (syncService != null) {
        await syncService!.syncPendingOperations();
      }

      final items = await itemRepository.fetchItems(
        userId: event.userId,
        pageSize: pageSize,
        categoryFilter: state.categoryFilter,
        isActiveFilter: state.isActiveFilter,
      );

      final lastDoc = await itemRepository.getLastDocument(
        userId: event.userId,
        pageSize: pageSize,
        categoryFilter: state.categoryFilter,
        isActiveFilter: state.isActiveFilter,
      );

      emit(
        state.copyWith(
          status: ItemListStatus.success,
          items: items,
          hasReachedMax: items.length < pageSize,
          lastDocument: lastDoc,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreItems(
    LoadMoreItems event,
    Emitter<ItemListState> emit,
  ) async {
    if (state.hasReachedMax) return;

    try {
      emit(state.copyWith(status: ItemListStatus.loadingMore));

      final newItems = await itemRepository.fetchItems(
        userId: event.userId,
        pageSize: pageSize,
        lastDocument: state.lastDocument,
        categoryFilter: state.categoryFilter,
        isActiveFilter: state.isActiveFilter,
      );

      if (newItems.isEmpty) {
        emit(
          state.copyWith(status: ItemListStatus.success, hasReachedMax: true),
        );
      } else {
        final lastDoc = await itemRepository.getLastDocument(
          userId: event.userId,
          pageSize: state.items.length + newItems.length,
          categoryFilter: state.categoryFilter,
          isActiveFilter: state.isActiveFilter,
        );

        emit(
          state.copyWith(
            status: ItemListStatus.success,
            items: List.of(state.items)..addAll(newItems),
            hasReachedMax: newItems.length < pageSize,
            lastDocument: lastDoc,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemListStatus.success,
          hasReachedMax: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshItems(
    RefreshItems event,
    Emitter<ItemListState> emit,
  ) async {
    try {
      // Sync pending operations before refreshing
      if (syncService != null) {
        await syncService!.syncPendingOperations();
      }

      final items = await itemRepository.fetchItems(
        userId: event.userId,
        pageSize: pageSize,
        categoryFilter: state.categoryFilter,
        isActiveFilter: state.isActiveFilter,
      );

      final lastDoc = await itemRepository.getLastDocument(
        userId: event.userId,
        pageSize: pageSize,
        categoryFilter: state.categoryFilter,
        isActiveFilter: state.isActiveFilter,
      );

      emit(
        state.copyWith(
          status: ItemListStatus.success,
          items: items,
          hasReachedMax: items.length < pageSize,
          lastDocument: lastDoc,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAddNewItem(
    AddNewItem event,
    Emitter<ItemListState> emit,
  ) async {
    final updatedItems = [event.item, ...state.items];
    emit(state.copyWith(items: updatedItems, status: ItemListStatus.success));
  }

  Future<void> _onFilterItems(
    FilterItems event,
    Emitter<ItemListState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemListStatus.loading));

      
      if (syncService != null) {
        await syncService!.syncPendingOperations();
      }

      final items = await itemRepository.fetchItems(
        userId: event.userId,
        pageSize: pageSize,
        categoryFilter: event.category,
        isActiveFilter: event.isActive,
      );

      final lastDoc = await itemRepository.getLastDocument(
        userId: event.userId,
        pageSize: pageSize,
        categoryFilter: event.category,
        isActiveFilter: event.isActive,
      );

      emit(
        state.copyWith(
          status: ItemListStatus.success,
          items: items,
          hasReachedMax: items.length < pageSize,
          lastDocument: lastDoc,
          categoryFilter: event.category,
          isActiveFilter: event.isActive,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<ItemListState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemListStatus.loading, clearFilters: true));

      final items = await itemRepository.fetchItems(
        userId: event.userId,
        pageSize: pageSize,
      );

      final lastDoc = await itemRepository.getLastDocument(
        userId: event.userId,
        pageSize: pageSize,
      );

      emit(
        state.copyWith(
          status: ItemListStatus.success,
          items: items,
          hasReachedMax: items.length < pageSize,
          lastDocument: lastDoc,
          clearFilters: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteItem(
    DeleteItem event,
    Emitter<ItemListState> emit,
  ) async {
    try {
      await itemRepository.deleteItem(event.itemId);

      final updatedItems =
          state.items.where((item) => item.id != event.itemId).toList();

      emit(
        state.copyWith(
          items: updatedItems,
          status: ItemListStatus.success,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
