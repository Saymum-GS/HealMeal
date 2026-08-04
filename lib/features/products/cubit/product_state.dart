import 'package:equatable/equatable.dart';

import '../../../core/models.dart';

enum ProductSort {
  relevance,
  alphabetical,
}

class ProductState extends Equatable {
  const ProductState({
    this.loading = true,
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.activeCategory,
    this.sortBy = ProductSort.relevance,
  });

  final bool loading;
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final String? activeCategory;
  final ProductSort sortBy;

  ProductState copyWith({
    bool? loading,
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String? activeCategory,
    ProductSort? sortBy,
  }) {
    return ProductState(
      loading: loading ?? this.loading,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      activeCategory: activeCategory ?? this.activeCategory,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    allProducts,
    filteredProducts,
    activeCategory,
    sortBy,
  ];
}
