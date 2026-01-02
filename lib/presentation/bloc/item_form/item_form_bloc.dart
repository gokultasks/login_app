import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/item_repository.dart';
import 'item_form_event.dart';
import 'item_form_state.dart';

class ItemFormBloc extends Bloc<ItemFormEvent, ItemFormState> {
  final ItemRepository itemRepository;

  ItemFormBloc({required this.itemRepository}) : super(const ItemFormState()) {
    on<TitleChanged>(_onTitleChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<CategoryChanged>(_onCategoryChanged);
    on<IsActiveChanged>(_onIsActiveChanged);
    on<FormSubmitted>(_onFormSubmitted);
    on<UpdateItem>(_onUpdateItem);
    on<FormReset>(_onFormReset);
  }

  void _onTitleChanged(TitleChanged event, Emitter<ItemFormState> emit) {
    final title = event.title;
    String? error;

    if (title.isEmpty) {
      error = 'Title is required';
    } else if (title.length < 3) {
      error = 'Title must be at least 3 characters';
    } else if (title.length > 50) {
      error = 'Title must not exceed 50 characters';
    }

    emit(
      state.copyWith(
        title: title,
        titleError: error,
        clearTitleError: error == null,
        status: FormStatus.initial,
      ),
    );
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<ItemFormState> emit,
  ) {
    final description = event.description;
    String? error;

    if (description.isEmpty) {
      error = 'Description is required';
    } else if (description.length < 10) {
      error = 'Description must be at least 10 characters';
    } else if (description.length > 200) {
      error = 'Description must not exceed 200 characters';
    }

    emit(
      state.copyWith(
        description: description,
        descriptionError: error,
        clearDescriptionError: error == null,
        status: FormStatus.initial,
      ),
    );
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<ItemFormState> emit) {
    final category = event.category;
    String? error;

    if (category.isEmpty) {
      error = 'Category is required';
    }

    emit(
      state.copyWith(
        category: category,
        categoryError: error,
        clearCategoryError: error == null,
        status: FormStatus.initial,
      ),
    );
  }

  void _onIsActiveChanged(IsActiveChanged event, Emitter<ItemFormState> emit) {
    emit(state.copyWith(isActive: event.isActive, status: FormStatus.initial));
  }

  Future<void> _onFormSubmitted(
    FormSubmitted event,
    Emitter<ItemFormState> emit,
  ) async {
    String? titleError;
    if (state.title.isEmpty) {
      titleError = 'Title is required';
    } else if (state.title.length < 3) {
      titleError = 'Title must be at least 3 characters';
    } else if (state.title.length > 50) {
      titleError = 'Title must not exceed 50 characters';
    }

    String? descriptionError;
    if (state.description.isEmpty) {
      descriptionError = 'Description is required';
    } else if (state.description.length < 10) {
      descriptionError = 'Description must be at least 10 characters';
    } else if (state.description.length > 200) {
      descriptionError = 'Description must not exceed 200 characters';
    }

    String? categoryError;
    if (state.category.isEmpty) {
      categoryError = 'Category is required';
    }

    if (titleError != null ||
        descriptionError != null ||
        categoryError != null) {
      emit(
        state.copyWith(
          titleError: titleError,
          descriptionError: descriptionError,
          categoryError: categoryError,
        ),
      );
      return;
    }

    if (!state.isValid) {
      return;
    }

    try {
      emit(state.copyWith(status: FormStatus.submitting));

      final item = await itemRepository.addItem(
        userId: event.userId,
        title: state.title,
        description: state.description,
        category: state.category,
        isActive: state.isActive,
      );

      emit(state.copyWith(status: FormStatus.success, createdItem: item));
    } catch (error) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<ItemFormState> emit,
  ) async {
    String? titleError;
    if (state.title.isEmpty) {
      titleError = 'Title is required';
    } else if (state.title.length < 3) {
      titleError = 'Title must be at least 3 characters';
    } else if (state.title.length > 50) {
      titleError = 'Title must not exceed 50 characters';
    }

    String? descriptionError;
    if (state.description.isEmpty) {
      descriptionError = 'Description is required';
    } else if (state.description.length < 10) {
      descriptionError = 'Description must be at least 10 characters';
    } else if (state.description.length > 200) {
      descriptionError = 'Description must not exceed 200 characters';
    }

    String? categoryError;
    if (state.category.isEmpty) {
      categoryError = 'Category is required';
    }

    if (titleError != null ||
        descriptionError != null ||
        categoryError != null) {
      emit(
        state.copyWith(
          titleError: titleError,
          descriptionError: descriptionError,
          categoryError: categoryError,
        ),
      );
      return;
    }

    if (!state.isValid) {
      return;
    }

    try {
      emit(state.copyWith(status: FormStatus.submitting));

      await itemRepository.updateItem(
        itemId: event.itemId,
        title: state.title,
        description: state.description,
        category: state.category,
        isActive: state.isActive,
      );

      emit(state.copyWith(status: FormStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onFormReset(FormReset event, Emitter<ItemFormState> emit) {
    emit(const ItemFormState());
  }
}
