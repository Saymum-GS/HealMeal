import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:healmeal_app/core/models.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit() : super(ProductState());

  StreamSubscription? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void load() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen(
          (snapshot) {
            final products = snapshot.docs
                .map((doc) {
                  try {
                    return Product.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    debugPrint('Error parsing product ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<Product>()
                .toList();

            emit(
              state.copyWith(
                loading: false,
                allProducts: products,
                filteredProducts: products,
              ),
            );
          },
          onError: (e) {
            emit(
              state.copyWith(
                loading: false,
                allProducts: [],
                filteredProducts: [],
              ),
            );
          },
        );
  }

  void filter({String? category, String? query}) {
    emit(state.copyWith(loading: true));

    var products = List.of(state.allProducts);
    final activeCategory = category ?? state.activeCategory;

    if (activeCategory != null &&
        activeCategory.isNotEmpty &&
        activeCategory != 'all') {
      products = products
          .where((item) => item.categoryId == activeCategory)
          .toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final needle = query.toLowerCase();
      products = products
          .where(
            (item) =>
                item.drugName.toLowerCase().contains(needle) ||
                item.manufacturer.toLowerCase().contains(needle),
          )
          .toList();
    }

    _applySortAndEmit(products, activeCategory, state.sortBy);
  }

  void sort(ProductSort sortBy) {
    _applySortAndEmit(
      List.of(state.filteredProducts),
      state.activeCategory,
      sortBy,
    );
  }

  void _applySortAndEmit(
    List<Product> products,
    String? category,
    ProductSort sortBy,
  ) {
    switch (sortBy) {
      case ProductSort.alphabetical:
        products.sort(
          (a, b) =>
              a.drugName.toLowerCase().compareTo(b.drugName.toLowerCase()),
        );
        break;
      case ProductSort.relevance:
        break;
    }

    emit(
      state.copyWith(
        loading: false,
        filteredProducts: products,
        activeCategory: category,
        sortBy: sortBy,
      ),
    );
  }
}
