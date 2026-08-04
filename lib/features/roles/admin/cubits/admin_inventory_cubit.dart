import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';

// States
abstract class AdminInventoryState extends Equatable {
  const AdminInventoryState();
  @override
  List<Object?> get props => [];
}

class AdminInventoryInitial extends AdminInventoryState {}

class AdminInventoryLoading extends AdminInventoryState {}

class AdminInventoryLoaded extends AdminInventoryState {
  final List<Product> lowStockProducts;
  final List<Product> outOfStockProducts;
  final List<Product> allProducts;
  final bool isSearching;
  const AdminInventoryLoaded({
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.allProducts,
    this.isSearching = false,
  });
  @override
  List<Object?> get props => [
    lowStockProducts,
    outOfStockProducts,
    allProducts,
    isSearching,
  ];
}

class AdminInventoryError extends AdminInventoryState {
  final String message;
  const AdminInventoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class AdminInventoryCubit extends Cubit<AdminInventoryState> {
  AdminInventoryCubit(this._productRepo) : super(AdminInventoryInitial());

  final ProductRepository _productRepo;

  Future<void> loadInventory() async {
    emit(AdminInventoryLoading());
    try {
      final outOfStock = await _productRepo.getOutOfStockProducts(limit: 50);
      final lowStock = await _productRepo.getLowStockProducts(limit: 50);
      final all = await _productRepo.getAllProducts(limit: 100, status: null);

      emit(
        AdminInventoryLoaded(
          lowStockProducts: lowStock,
          outOfStockProducts: outOfStock,
          allProducts: all.products,
        ),
      );
    } catch (e) {
      emit(AdminInventoryError(e.toString()));
    }
  }

  Future<void> searchAllProducts(String query) async {
    if (state is AdminInventoryLoaded) {
      final s = state as AdminInventoryLoaded;
      emit(
        AdminInventoryLoaded(
          lowStockProducts: s.lowStockProducts,
          outOfStockProducts: s.outOfStockProducts,
          allProducts: s.allProducts,
          isSearching: true,
        ),
      );

      try {
        if (query.trim().isEmpty) {
          final all = await _productRepo.getAllProducts(
            limit: 100,
            status: null,
          );
          emit(
            AdminInventoryLoaded(
              lowStockProducts: s.lowStockProducts,
              outOfStockProducts: s.outOfStockProducts,
              allProducts: all.products,
              isSearching: false,
            ),
          );
        } else {
          final result = await _productRepo.searchProducts(
            query,
            limit: 100,
            status: null,
          );
          emit(
            AdminInventoryLoaded(
              lowStockProducts: s.lowStockProducts,
              outOfStockProducts: s.outOfStockProducts,
              allProducts: result.products,
              isSearching: false,
            ),
          );
        }
      } catch (e) {
        emit(AdminInventoryError(e.toString()));
      }
    }
  }

  Future<void> updateStock(String productId, int newCount) async {
    if (state is AdminInventoryLoaded) {
      final s = state as AdminInventoryLoaded;
      final newAll = s.allProducts
          .map(
            (p) => p.id == productId ? p.copyWith(countInStock: newCount) : p,
          )
          .toList();
      final newLow = s.lowStockProducts
          .map(
            (p) => p.id == productId ? p.copyWith(countInStock: newCount) : p,
          )
          .toList();
      final newOut = s.outOfStockProducts
          .map(
            (p) => p.id == productId ? p.copyWith(countInStock: newCount) : p,
          )
          .toList();

      emit(
        AdminInventoryLoaded(
          lowStockProducts: newLow,
          outOfStockProducts: newOut,
          allProducts: newAll,
        ),
      );
    }

    try {
      await _productRepo.updateStock(productId, newCount);
    } catch (e) {
      // Revert optimistic update? Or just emit error.
      emit(AdminInventoryError(e.toString()));
      rethrow;
    }
  }
}
