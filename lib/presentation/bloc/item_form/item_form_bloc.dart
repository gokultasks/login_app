import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/local/draft_storage.dart';
import 'item_form_event.dart';
import 'item_form_state.dart';

class ItemFormBloc extends Bloc<ItemFormEvent, ItemFormState> {
  final ItemRepository itemRepository;
  final DraftStorage draftStorage;

  ItemFormBloc({
    required this.itemRepository,
    required this.draftStorage,
  }) : super(const ItemFormState()) {
    
    on<FieldChanged>(_onFieldChanged);
    
    
    on<FormInitialized>(_onFormInitialized);
    on<PartialSaveRequested>(_onPartialSaveRequested);
    on<SubmitRequested>(_onSubmitRequested);
    on<FormReset>(_onFormReset);
    
    
    on<TitleChanged>(_onTitleChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<CategoryChanged>(_onCategoryChanged);
    on<IsActiveChanged>(_onIsActiveChanged);
    on<FormSubmitted>(_onFormSubmitted);
  }


  Future<void> _onFormInitialized(
    FormInitialized event,
    Emitter<ItemFormState> emit,
  ) async {
    if (event.initialData != null) {

      final data = event.initialData!;
      emit(ItemFormState.fromJson(data).copyWith(itemId: event.itemId));
      _validateForm(emit);
    } else if (await draftStorage.hasDraft()) {
      
      final draft = await draftStorage.loadDraft();
      if (draft != null) {
        emit(ItemFormState.fromJson(draft).copyWith(isDraftLoaded: true));
        _validateForm(emit);
      }
    }
  }

  
  void _onFieldChanged(FieldChanged event, Emitter<ItemFormState> emit) {
    ItemFormState newState = state;

    switch (event.key) {
      case FormFieldKey.title:
        newState = state.copyWith(title: event.value as String);
        break;
      case FormFieldKey.description:
        newState = state.copyWith(description: event.value as String);
        break;
      case FormFieldKey.category:
        final newCategory = event.value as String;
        newState = state.copyWith(
          category: newCategory,
          
          clearEstimatedHours: newCategory != 'Business',
          clearBudget: newCategory != 'Business',
        );
        break;
      case FormFieldKey.isActive:
        final isActive = event.value as bool;
        newState = state.copyWith(
          isActive: isActive,
          
          clearDueDate: !isActive,
          
          clearBudget: !isActive && state.category == 'Business',
        );
        break;
      case FormFieldKey.dueDate:
        newState = state.copyWith(
          dueDate: event.value as DateTime?,
          clearDueDate: event.value == null,
        );
        break;
      case FormFieldKey.estimatedHours:
        newState = state.copyWith(
          estimatedHours: event.value as double?,
          clearEstimatedHours: event.value == null,
        );
        break;
      case FormFieldKey.budget:
        newState = state.copyWith(
          budget: event.value as double?,
          clearBudget: event.value == null,
        );
        break;
    }

    emit(newState);
    _validateForm(emit);
  }

  Future<void> _onPartialSaveRequested(
    PartialSaveRequested event,
    Emitter<ItemFormState> emit,
  ) async {
    await draftStorage.saveDraft(state.toJson());
  }

  Future<void> _onSubmitRequested(
    SubmitRequested event,
    Emitter<ItemFormState> emit,
  ) async {
    
    _validateForm(emit);

    if (!state.isValid) {
      emit(state.copyWith(
        status: FormStatus.failure,
        globalError: 'Please fix all errors before submitting',
      ));
      return;
    }

    try {
      emit(state.copyWith(status: FormStatus.loading));

      ItemModel item;
      if (state.itemId != null) {
     
        await itemRepository.updateItem(
          itemId: state.itemId!,
          title: state.title,
          description: state.description,
          category: state.category,
          isActive: state.isActive,
          dueDate: state.dueDate,
          estimatedHours: state.estimatedHours,
          budget: state.budget,
        );
        
        item = ItemModel(
          id: state.itemId!,
          userId: event.userId,
          title: state.title,
          description: state.description,
          category: state.category,
          isActive: state.isActive,
          createdAt: DateTime.now(), 
          dueDate: state.dueDate,
          estimatedHours: state.estimatedHours,
          budget: state.budget,
        );
      } else {
        
        item = await itemRepository.addItem(
          userId: event.userId,
          title: state.title,
          description: state.description,
          category: state.category,
          isActive: state.isActive,
          dueDate: state.dueDate,
          estimatedHours: state.estimatedHours,
          budget: state.budget,
        );
      }


      await draftStorage.clearDraft();

      emit(state.copyWith(status: FormStatus.success, createdItem: item));
    } catch (error) {
      emit(state.copyWith(
        status: FormStatus.failure,
        globalError: error.toString(),
      ));
    }
  }


  void _validateForm(Emitter<ItemFormState> emit) {
    final errors = <FormFieldKey, String?>{};

    if (state.title.isEmpty) {
      errors[FormFieldKey.title] = 'Title is required';
    } else if (state.title.length < 3) {
      errors[FormFieldKey.title] = 'Title must be at least 3 characters';
    } else if (state.title.length > 50) {
      errors[FormFieldKey.title] = 'Title must not exceed 50 characters';
    }

    
    if (state.description.length < 30) {
      errors[FormFieldKey.description] =
          'Description must be at least 30 characters';
    } else if (state.description.length > 200) {
      errors[FormFieldKey.description] =
          'Description must not exceed 200 characters';
    }

    
    if (state.category.isEmpty) {
      errors[FormFieldKey.category] = 'Category is required';
    }

    
    if (state.isActive && state.dueDate == null) {
      errors[FormFieldKey.dueDate] = 'Due date is required for active items';
    }

    
    if (state.category == 'Business' && state.estimatedHours == null) {
      errors[FormFieldKey.estimatedHours] =
          'Estimated hours required for Business items';
    } else if (state.estimatedHours != null && state.estimatedHours! <= 0) {
      errors[FormFieldKey.estimatedHours] = 'Hours must be greater than 0';
    }

    
    if (state.category == 'Business' && state.isActive && state.budget == null) {
      errors[FormFieldKey.budget] =
          'Budget is required for active Business items';
    } else if (state.budget != null && state.budget! < 0) {
      errors[FormFieldKey.budget] = 'Budget cannot be negative';
    }

    final isValid = errors.values.every((error) => error == null);
    emit(state.copyWith(
      errors: errors,
      validationStatus:
          isValid ? ValidationStatus.valid : ValidationStatus.invalid,
    ));
  }

  // Legacy handlers for backward compatibility
  // Legacy handlers for backward compatibility
  void _onTitleChanged(TitleChanged event, Emitter<ItemFormState> emit) {
    emit(state.copyWith(title: event.title));
    _validateForm(emit);
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<ItemFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
    _validateForm(emit);
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<ItemFormState> emit) {
    final newCategory = event.category;
    emit(state.copyWith(
      category: newCategory,
      clearEstimatedHours: newCategory != 'Business',
      clearBudget: newCategory != 'Business',
    ));
    _validateForm(emit);
  }

  void _onIsActiveChanged(IsActiveChanged event, Emitter<ItemFormState> emit) {
    emit(state.copyWith(
      isActive: event.isActive,
      clearDueDate: !event.isActive,
      clearBudget: !event.isActive && state.category == 'Business',
    ));
    _validateForm(emit);
  }

  Future<void> _onFormSubmitted(
    FormSubmitted event,
    Emitter<ItemFormState> emit,
  ) async {
    add(SubmitRequested(event.userId));
  }

  void _onFormReset(FormReset event, Emitter<ItemFormState> emit) {
    draftStorage.clearDraft();
    emit(const ItemFormState());
  }
}
