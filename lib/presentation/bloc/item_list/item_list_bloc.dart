import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/item_repository.dart';
import 'item_list_event.dart';
import 'item_list_state.dart';

class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  final ItemRepository itemRepository;
  static const int pageSize = 15;

  ItemListBloc({required this.itemRepository}) : super(const ItemListState()) {
    on<LoadItems>(_onLoadItems);
    on<LoadMoreItems>(_onLoadMoreItems);
    on<RefreshItems>(_onRefreshItems);
    on<AddNewItem>(_onAddNewItem);
  }

  Future<void> _onLoadItems(
    LoadItems event,
    Emitter<ItemListState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemListStatus.loading));

      final items = await itemRepository.fetchItems(
        page: 0,
        pageSize: pageSize,
      );

      emit(
        state.copyWith(
          status: ItemListStatus.success,
          items: items,
          hasReachedMax: false,
          currentPage: 0,
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

      final nextPage = state.currentPage + 1;
      final newItems = await itemRepository.fetchItems(
        page: nextPage,
        pageSize: pageSize,
      );

      if (newItems.isEmpty) {
        emit(
          state.copyWith(status: ItemListStatus.success, hasReachedMax: true),
        );
      } else {
        emit(
          state.copyWith(
            status: ItemListStatus.success,
            items: List.of(state.items)..addAll(newItems),
            hasReachedMax: false,
            currentPage: nextPage,
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
      final items = await itemRepository.fetchItems(
        page: 0,
        pageSize: pageSize,
      );

      emit(
        state.copyWith(
          status: ItemListStatus.success,
          items: items,
          hasReachedMax: false,
          currentPage: 0,
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
}
