import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';
import '../../../../core/services.dart';

abstract class AdminCategoriesState extends Equatable {
  const AdminCategoriesState();
  @override
  List<Object?> get props => [];
}

class AdminCategoriesInitial extends AdminCategoriesState {}

class AdminCategoriesLoaded extends AdminCategoriesState {
  const AdminCategoriesLoaded(this.categories);
  final List<AppCategory> categories;
  @override
  List<Object?> get props => [categories];
}

class AdminCategoriesCubit extends Cubit<AdminCategoriesState> {
  AdminCategoriesCubit() : super(AdminCategoriesInitial());

  Future<void> loadCategories() async {
    final repo = getIt<CategoryRepository>();
    final categories = await repo.getCategories();
    emit(AdminCategoriesLoaded(categories));
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (state is! AdminCategoriesLoaded) return;
    final currentState = state as AdminCategoriesLoaded;

    final currentList = List<AppCategory>.from(currentState.categories);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);

    // Optimistic update
    emit(AdminCategoriesLoaded(currentList));

    final repo = getIt<CategoryRepository>();
    for (int i = 0; i < currentList.length; i++) {
      final updatedCat = currentList[i];
      // We only update if sortOrder changed to avoid spamming writes
      if (updatedCat.sortOrder != i + 1) {
        final newCat = AppCategory(
          id: updatedCat.id,
          name: updatedCat.name,
          slug: updatedCat.slug,
          iconKey: updatedCat.iconKey,
          colorHex: updatedCat.colorHex,
          sortOrder: i + 1,
          isActive: updatedCat.isActive,
        );
        await repo.saveCategory(newCat);
      }
    }
    // Reload from network to ensure consistency
    loadCategories();
  }

  Future<void> toggleVisibility(AppCategory category, bool isActive) async {
    if (state is AdminCategoriesLoaded) {
      final currentState = state as AdminCategoriesLoaded;
      final currentList = List<AppCategory>.from(currentState.categories);
      final idx = currentList.indexWhere((c) => c.id == category.id);
      if (idx != -1) {
        currentList[idx] = currentList[idx].copyWith(isActive: isActive);
        emit(AdminCategoriesLoaded(currentList));
      }
    }

    final repo = getIt<CategoryRepository>();
    final newCat = AppCategory(
      id: category.id,
      name: category.name,
      slug: category.slug,
      iconKey: category.iconKey,
      colorHex: category.colorHex,
      sortOrder: category.sortOrder,
      isActive: isActive,
    );
    try {
      await repo.saveCategory(newCat);
    } catch (e) {
      // Revert on error could be implemented here
    }
  }

  Future<void> createCategory(String slug, String name, String icon) async {
    try {
      final repo = getIt<CategoryRepository>();
      await repo.addCategory(slug, name, icon);
      loadCategories();
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> updateCategory(AppCategory category) async {
    try {
      final repo = getIt<CategoryRepository>();
      await repo.saveCategory(category);
      loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final repo = getIt<CategoryRepository>();
      await repo.deleteCategory(id);
      loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}
