import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'package:carlog/features/logs/domain/repositories/category_repository.dart';
import 'package:carlog/features/logs/data/models/category_model.dart';
import 'category_event.dart';
import 'category_state.dart';

@injectable
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryBloc(this._categoryRepository) : super(const CategoryState()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddUserCategory>(_onAddUserCategory);
    on<DeleteUserCategory>(_onDeleteUserCategory);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoryState> emit) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    try {
      final categories = await _categoryRepository.getCategories();
      emit(state.copyWith(status: CategoryStatus.loaded, categories: categories));
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddUserCategory(AddUserCategory event, Emitter<CategoryState> emit) async {
    try {
      final newCategory = CategoryModel(
        id: const Uuid().v4(),
        name: event.name,
        type: 'user_defined',
        iconCodePoint: event.iconCodePoint,
      );
      await _categoryRepository.addCategory(newCategory);
      add(LoadCategories());
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteUserCategory(DeleteUserCategory event, Emitter<CategoryState> emit) async {
    try {
      await _categoryRepository.deleteCategory(event.id);
      add(LoadCategories());
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.error, errorMessage: e.toString()));
    }
  }
}
