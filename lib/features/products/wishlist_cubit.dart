import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../core/utils.dart';
import '../../../core/services.dart';

class WishlistState extends Equatable {
  const WishlistState({
    this.productIds = const [],
    this.products = const [],
    this.notifiedProductIds = const {},
  });

  final List<String> productIds;
  final List<Product> products;
  final Set<String> notifiedProductIds;

  WishlistState copyWith({
    List<String>? productIds,
    List<Product>? products,
    Set<String>? notifiedProductIds,
  }) {
    return WishlistState(
      productIds: productIds ?? this.productIds,
      products: products ?? this.products,
      notifiedProductIds: notifiedProductIds ?? this.notifiedProductIds,
    );
  }

  @override
  List<Object?> get props => [productIds, products, notifiedProductIds];
}

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(WishlistState());

  static const _wishlistKey = 'healmeal_wishlist_v1';
  static const _notifiedKey = 'healmeal_notified_v1';

  Future<void> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_wishlistKey) ?? [];
    Set<String> notified = (prefs.getStringList(_notifiedKey) ?? []).toSet();

    final userId = AppSession.userId;
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc('current')
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            if (data['productIds'] != null) {
              list = List<String>.from(data['productIds']);
              await prefs.setStringList(_wishlistKey, list);
            }
            if (data['notifiedProductIds'] != null) {
              notified = List<String>.from(data['notifiedProductIds']).toSet();
              await prefs.setStringList(_notifiedKey, notified.toList());
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading wishlist from Firestore: $e');
      }
    }

    emit(state.copyWith(productIds: list, notifiedProductIds: notified));
    _fetchWishlistProducts(list);
  }

  Future<void> _fetchWishlistProducts(List<String> ids) async {
    if (ids.isEmpty) {
      emit(state.copyWith(products: []));
      return;
    }
    try {
      final repo = getIt<ProductRepository>();
      final products = await repo.getProductsByIds(ids);
      emit(state.copyWith(products: products));
    } catch (e) {
      debugPrint('Error fetching wishlist products: $e');
    }
  }

  Future<void> toggleWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = List<String>.from(state.productIds);

    if (currentList.contains(productId)) {
      currentList.remove(productId);
    } else {
      currentList.add(productId);
    }

    await prefs.setStringList(_wishlistKey, currentList);

    final userId = AppSession.userId;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc('current')
            .set({'productIds': currentList}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving wishlist to Firestore: $e');
      }
    }

    emit(state.copyWith(productIds: currentList));
    _fetchWishlistProducts(currentList);
  }

  Future<void> notifyWhenAvailable(String productId) async {
    final next = Set<String>.from(state.notifiedProductIds)..add(productId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_notifiedKey, next.toList());

    final userId = AppSession.userId;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc('current')
            .set({
              'notifiedProductIds': next.toList(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving notified products to Firestore: $e');
      }
    }

    emit(state.copyWith(notifiedProductIds: next));
  }

  Future<void> removeNotifiedProduct(String productId) async {
    final next = Set<String>.from(state.notifiedProductIds)..remove(productId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_notifiedKey, next.toList());

    final userId = AppSession.userId;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc('current')
            .set({
              'notifiedProductIds': next.toList(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving notified products to Firestore: $e');
      }
    }

    emit(state.copyWith(notifiedProductIds: next));
  }
}
