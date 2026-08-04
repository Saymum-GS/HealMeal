import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../core/services.dart';
import 'package:equatable/equatable.dart';

enum ProductSort {
  relevance,
  alphabetical,
}

class ProductCubit extends Cubit<ProductState> {
  ProductCubit() : super(ProductState());

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      emit(
        state.copyWith(
          loading: true,
          clearLastDocument: true,
          hasMore: true,
          allProducts: [],
          filteredProducts: [],
        ),
      );
    } else if (state.allProducts.isEmpty) {
      emit(state.copyWith(loading: true));
    } else {
      return;
    }

    try {
      final repo = getIt<ProductRepository>();
      final result = await _fetchFromRepo(repo, limit: 20);

      emit(
        state.copyWith(
          loading: false,
          allProducts: result.products,
          filteredProducts: result.products,
          lastDocument: result.lastDoc,
          hasMore: result.products.length >= 20,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.loading) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final repo = getIt<ProductRepository>();
      final result = await _fetchFromRepo(
        repo,
        limit: 20,
        startAfter: state.lastDocument,
      );

      final updatedProducts = List<Product>.from(state.allProducts)
        ..addAll(result.products);

      emit(
        state.copyWith(
          isLoadingMore: false,
          allProducts: updatedProducts,
          filteredProducts: updatedProducts,
          lastDocument: result.lastDoc,
          hasMore: result.products.length >= 20,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})> _fetchFromRepo(
    ProductRepository repo, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (state.searchQuery != null && state.searchQuery!.trim().isNotEmpty) {
      return repo.searchProducts(
        state.searchQuery!,
        limit: limit,
        startAfter: startAfter,
        status: state.activeStatus,
      );
    } else if (state.activeCategory != null) {
      return repo.getProductsByCategory(
        categoryId: state.activeCategory!,
        limit: limit,
        startAfter: startAfter,
        status: state.activeStatus,
      );
    } else if (state.activeCollection != null) {
      return repo.getProductsByCollection(
        collection: state.activeCollection!,
        limit: limit,
        startAfter: startAfter,
        status: state.activeStatus,
      );
    } else {
      return repo.getAllProducts(
        limit: limit,
        startAfter: startAfter,
        status: state.activeStatus,
      );
    }
  }

  void filter({
    String? category,
    String? query,
    ProductLifecycleStatus? status,
    String? collection,
    bool? featured,
    double? maxPrice,
  }) {
    bool queryChanged = false;

    if (category != state.activeCategory) {
      emit(
        state.copyWith(
          activeCategory: category,
          clearActiveCategory: category == null,
        ),
      );
      queryChanged = true;
    }
    if (query != state.searchQuery) {
      emit(state.copyWith(searchQuery: query));
      queryChanged = true;
    }
    if (status != state.activeStatus) {
      emit(
        state.copyWith(activeStatus: status, clearActiveStatus: status == null),
      );
      queryChanged = true;
    }
    if (collection != state.activeCollection) {
      emit(
        state.copyWith(
          activeCollection: collection,
          clearActiveCollection: collection == null,
        ),
      );
      queryChanged = true;
    }
    if (featured != state.featured) {
      emit(state.copyWith(featured: featured, clearFeatured: featured == null));
      queryChanged = true;
    }
    if (maxPrice != state.maxPrice) {
      emit(state.copyWith(maxPrice: maxPrice, clearMaxPrice: maxPrice == null));
      queryChanged = true;
    }

    if (queryChanged) {
      load(refresh: true);
    } else {
      _applyLocalSort();
    }
  }

  void sort(ProductSort sortType) {
    emit(state.copyWith(sortBy: sortType));
    _applyLocalSort();
  }

  void setCategory(String? categoryId) {
    if (categoryId != state.activeCategory) {
      emit(
        state.copyWith(
          activeCategory: categoryId,
          clearActiveCategory: categoryId == null,
        ),
      );
      load(refresh: true);
    }
  }

  void setLifecycleStatus(ProductLifecycleStatus? status) {
    if (status != state.activeStatus) {
      emit(
        state.copyWith(activeStatus: status, clearActiveStatus: status == null),
      );
      load(refresh: true);
    }
  }

  void _applyLocalSort() {
    List<Product> filtered = List<Product>.from(state.allProducts);

    if (state.featured == true) {
      filtered = filtered.where((p) => p.isFeatured).toList();
    }
    if (state.maxPrice != null) {
      filtered = filtered
          .where((p) => p.effectivePrice <= state.maxPrice!)
          .toList();
    }

    switch (state.sortBy) {
      case ProductSort.alphabetical:
        filtered.sort((a, b) => a.drugName.compareTo(b.drugName));
        break;
      case ProductSort.relevance:
        break;
    }

    emit(state.copyWith(filteredProducts: filtered));
  }
}

class ProductState extends Equatable {
  const ProductState({
    this.loading = true,
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.error,
    this.sortBy = ProductSort.relevance,
    this.activeCategory,
    this.activeCollection,
    this.searchQuery,
    this.activeStatus = ProductLifecycleStatus.active,
    this.lastDocument,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.featured,
    this.maxPrice,
  });

  final bool loading;
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final String? error;
  final ProductSort sortBy;
  final String? activeCategory;
  final String? activeCollection;
  final String? searchQuery;
  final ProductLifecycleStatus? activeStatus;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isLoadingMore;
  final bool? featured;
  final double? maxPrice;

  ProductState copyWith({
    bool? loading,
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    ProductSort? sortBy,
    String? activeCategory,
    String? activeCollection,
    String? searchQuery,
    ProductLifecycleStatus? activeStatus,
    bool clearActiveCategory = false,
    bool clearActiveCollection = false,
    bool clearActiveStatus = false,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearLastDocument = false,
    String? error,
    bool clearError = false,
    bool? featured,
    double? maxPrice,
    bool clearFeatured = false,
    bool clearMaxPrice = false,
  }) {
    return ProductState(
      loading: loading ?? this.loading,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      error: clearError ? null : (error ?? this.error),
      sortBy: sortBy ?? this.sortBy,
      activeCategory: clearActiveCategory
          ? null
          : (activeCategory ?? this.activeCategory),
      activeCollection: clearActiveCollection
          ? null
          : (activeCollection ?? this.activeCollection),
      searchQuery: searchQuery ?? this.searchQuery,
      activeStatus: clearActiveStatus
          ? null
          : (activeStatus ?? this.activeStatus),
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      featured: clearFeatured ? null : (featured ?? this.featured),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    allProducts,
    filteredProducts,
    error,
    sortBy,
    activeCategory,
    activeCollection,
    searchQuery,
    activeStatus,
    lastDocument,
    hasMore,
    isLoadingMore,
    featured,
    maxPrice,
  ];
}
