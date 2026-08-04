import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: [])) {
    _loadCart();
  }

  static const _cartKey = 'healmeal_cart_v1';
  Timer? _debounceTimer;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _loadCart() async {
    try {
      final userId = AppSession.userId;
      String? jsonString;

      if (userId != null) {
        await fetchWalletBalance();

        final settingsDoc = await FirebaseFirestore.instance
            .collection('platform_settings')
            .doc('global')
            .get();
        if (settingsDoc.exists) {
          emit(
            state.copyWith(
              settings: PlatformSettings.fromMap(settingsDoc.data()!),
            ),
          );
        }

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc('current')
            .get();
        if (doc.exists) {
          final data = doc.data()?['items'];
          if (data is String) {
            jsonString = data;
          } else if (data is List) {
            final items = data
                .map(
                  (e) => CartEntry.fromMap(Map<String, dynamic>.from(e as Map)),
                )
                .toList();
            emit(state.copyWith(items: items));
            return;
          }
        }
      }

      if (jsonString == null) {
        final prefs = await SharedPreferences.getInstance();
        jsonString = prefs.getString(_cartKey);
      }

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final items = jsonList
            .map((e) => CartEntry.fromMap(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(items: items));
      }

      await syncCartWithServer();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> reloadAndMigrate() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cartKey);
    List<CartEntry> localItems = [];
    try {
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        localItems = jsonList
            .map((e) => CartEntry.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error decoding cart JSON during migration: $e');
    }

    // Clear local prefs so we don't pollute future guest sessions
    await prefs.remove(_cartKey);

    // Load existing firestore cart if any
    await _loadCart();

    // Merge
    if (localItems.isNotEmpty) {
      addMultipleItems(localItems.map((e) => e.product).toList());
    }
  }

  Future<void> _saveCart(List<CartEntry> items) async {
    try {
      final jsonString = jsonEncode(
        items.map((e) => e.toMap()).toList(),
        toEncodable: (item) {
          if (item is DateTime) return item.toIso8601String();
          if (item is Timestamp) return item.toDate().toIso8601String();
          return item.toString();
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, jsonString);

      final userId = AppSession.userId;
      if (userId != null) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(Duration(seconds: 2), () async {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('cart')
                .doc('current')
                .set({'items': items.map((e) => e.toMap()).toList()});
          } catch (e) {
            debugPrint('Error saving cart to Firestore: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  Future<void> syncCartWithServer() async {
    final oldItems = List<CartEntry>.from(state.items);
    if (oldItems.isEmpty) return;

    try {
      List<CartEntry> newItems = [];
      for (final item in oldItems) {
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item.product.id)
            .get();
        if (doc.exists) {
          final p = Product.fromMap(doc.data()!, doc.id);
          if (p.isAvailable &&
              p.lifecycleStatus != ProductLifecycleStatus.discontinued &&
              p.countInStock > 0) {
            final validQty = item.quantity.clamp(1, p.countInStock);
            newItems.add(item.copyWith(product: p, quantity: validQty.toInt()));
          }
        }
      }
      _emitValidatedState(newItems);
    } catch (e) {
      debugPrint('Error syncing cart with server: $e');
    }
  }

  void _emitValidatedState(List<CartEntry> items) {
    double newSubtotal = items.fold(0, (acc, item) => acc + item.subtotal);
    if (state.couponCode != null && newSubtotal < state.couponMinSpend) {
      emit(state.copyWith(items: items, clearCouponCode: true));
    } else {
      emit(state.copyWith(items: items));
    }
    _saveCart(items);
  }

  void addItem(Product product) {
    addItemWithQuantity(product, 1);
  }

  void addItemWithQuantity(Product product, int quantity) {
    if (quantity <= 0 || product.countInStock <= 0) return;
    final items = List<CartEntry>.from(state.items);
    final index = items.indexWhere(
      (element) => element.product.id == product.id,
    );
    if (index >= 0) {
      final newQuantity = (items[index].quantity + quantity).clamp(1, product.countInStock);
      items[index] = items[index].copyWith(quantity: newQuantity.toInt());
    } else {
      final initialQuantity = quantity.clamp(1, product.countInStock);
      items.add(CartEntry(product: product, quantity: initialQuantity.toInt()));
    }
    _emitValidatedState(items);
  }

  void addMultipleItems(List<Product> products) {
    final items = List<CartEntry>.from(state.items);
    for (final product in products) {
      final index = items.indexWhere(
        (element) => element.product.id == product.id,
      );
      if (index >= 0) {
        final newQuantity = (items[index].quantity + 1).clamp(1, 999);
        items[index] = items[index].copyWith(quantity: newQuantity.toInt());
      } else {
        items.add(CartEntry(product: product, quantity: 1));
      }
    }
    _emitValidatedState(items);
  }

  void removeItem(String productId) {
    final items = state.items
        .where((item) => item.product.id != productId)
        .toList();
    _emitValidatedState(items);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    
    // Find the current item to check its stock
    final entry = state.items.cast<CartEntry?>().firstWhere(
      (item) => item?.product.id == productId, 
      orElse: () => null,
    );
    
    if (entry == null) return;
    
    final validQty = quantity.clamp(1, entry.product.countInStock);
    final items = state.items
        .map(
          (item) => item.product.id == productId
              ? item.copyWith(quantity: validQty.toInt())
              : item,
        )
        .toList();
    _emitValidatedState(items);
  }

  Future<void> applyCoupon(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('coupons')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();

      // Validation: Expiration Date
      final Timestamp? expiration = data['expirationDate'] as Timestamp?;
      if (expiration != null && expiration.toDate().isBefore(DateTime.now())) {
        emit(
          state.copyWith(
            couponCode: null,
            couponDiscountPercent: 0.0,
            clearCouponCode: true,
          ),
        );
        throw Exception('This coupon has expired');
      }

      // Validation: Minimum Spend
      final double minSpend = (data['minimumSpend'] ?? 0.0).toDouble();
      if (subtotal < minSpend) {
        emit(
          state.copyWith(
            couponCode: null,
            couponDiscountPercent: 0.0,
            clearCouponCode: true,
          ),
        );
        throw Exception(
          'Minimum spend of ৳${minSpend.toStringAsFixed(2)} required for this coupon',
        );
      }

      // Validation: Max Uses
      final int maxUses = data['maxUses'] ?? 0;
      final int currentUses = data['usesCount'] ?? 0;
      if (maxUses > 0 && currentUses >= maxUses) {
        emit(
          state.copyWith(
            couponCode: null,
            couponDiscountPercent: 0.0,
            clearCouponCode: true,
          ),
        );
        throw Exception('This coupon has reached its usage limit');
      }

      final discountPercent = (data['discountPercent'] as num).toDouble();
      emit(
        state.copyWith(
          couponCode: code.trim().toUpperCase(),
          couponDiscountPercent: discountPercent,
          couponMinSpend: minSpend,
        ),
      );
    } else {
      emit(
        state.copyWith(
          couponCode: null,
          couponDiscountPercent: 0.0,
          clearCouponCode: true,
        ),
      );
      throw Exception('Invalid coupon code');
    }
  }

  void removeCoupon() {
    emit(
      state.copyWith(
        couponCode: null,
        couponDiscountPercent: 0.0,
        clearCouponCode: true,
      ),
    );
  }

  void toggleCashback(bool enabled) {
    emit(state.copyWith(cashbackEnabled: enabled));
  }

  void selectPayment(PaymentMethod method) {
    emit(state.copyWith(selectedPaymentMethod: method));
  }

  void clearCart() {
    emit(state.copyWith(items: []));
    _saveCart([]);
    fetchWalletBalance();
  }

  Future<void> fetchWalletBalance() async {
    final userId = AppSession.userId;
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists) {
          final balance = (doc.data()?['walletBalance'] ?? 0.0).toDouble();
          emit(state.copyWith(walletBalance: balance));
        }
      } catch (e) {
        debugPrint('Error fetching wallet balance: $e');
      }
    }
  }

  void setPrescriptionStatus(bool approved, {String? prescriptionId}) {
    emit(
      state.copyWith(
        hasAttachedPrescription: approved,
        prescriptionId: prescriptionId,
      ),
    );
  }

  int get totalCount => state.totalCount;
  double get subtotal => state.subtotal;
  double get discountAmount => state.discountAmount;
  double get deliveryCharge => state.deliveryCharge;
  double get cashbackEarned => state.cashbackEarned;
  double get cashbackUsed => state.cashbackUsed;
  double get taxAmount => state.taxAmount;
  double get totalPrice => state.totalPrice;
  double deliveryChargeForAddress(Address? address) =>
      state.deliveryChargeForAddress(address);
  double totalPriceForAddress(Address? address) =>
      state.totalPriceForAddress(address);
}

class CartEntry extends Equatable {
  const CartEntry({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  CartEntry copyWith({Product? product, int? quantity}) {
    return CartEntry(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {'product': product.toMap(), 'quantity': quantity};
  }

  factory CartEntry.fromMap(Map<String, dynamic> map) {
    return CartEntry(
      product: Product.fromMap(
        Map<String, dynamic>.from(map['product'] as Map? ?? {}),
        map['product']?['id'] ?? '',
      ),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  double get subtotal => product.effectivePrice * quantity;

  @override
  List<Object?> get props => [product, quantity];
}

class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.couponCode,
    this.couponDiscountPercent = 0.0,
    this.couponMinSpend = 0.0,
    this.cashbackEnabled = false,
    this.selectedPaymentMethod = PaymentMethod.cod,
    this.hasAttachedPrescription = false,
    this.prescriptionId,
    this.walletBalance = 0.0,
    this.settings = const PlatformSettings(
      deliveryCharge: 60.0,
      freeDeliveryThreshold: 500.0,
      cashbackPercentage: 8.0,
      maxCashbackAmount: 125.5,
      taxRate: 0.0,
    ),
  });

  final List<CartEntry> items;
  final String? couponCode;
  final double couponDiscountPercent;
  final double couponMinSpend;
  final bool cashbackEnabled;
  final PaymentMethod selectedPaymentMethod;
  final bool hasAttachedPrescription;
  final String? prescriptionId;
  final double walletBalance;
  final PlatformSettings settings;

  CartState copyWith({
    List<CartEntry>? items,
    String? couponCode,
    double? couponDiscountPercent,
    double? couponMinSpend,
    bool? cashbackEnabled,
    PaymentMethod? selectedPaymentMethod,
    bool? hasAttachedPrescription,
    String? prescriptionId,
    double? walletBalance,
    PlatformSettings? settings,
    bool clearCouponCode = false,
  }) {
    return CartState(
      items: items ?? this.items,
      couponCode: clearCouponCode ? null : (couponCode ?? this.couponCode),
      couponDiscountPercent: clearCouponCode
          ? 0.0
          : (couponDiscountPercent ?? this.couponDiscountPercent),
      couponMinSpend: clearCouponCode
          ? 0.0
          : (couponMinSpend ?? this.couponMinSpend),
      cashbackEnabled: cashbackEnabled ?? this.cashbackEnabled,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      hasAttachedPrescription:
          hasAttachedPrescription ?? this.hasAttachedPrescription,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      walletBalance: walletBalance ?? this.walletBalance,
      settings: settings ?? this.settings,
    );
  }

  int get totalCount => items.fold(0, (acc, item) => acc + item.quantity);
  double get subtotal => items.fold(0, (acc, item) => acc + item.subtotal);
  double get discountAmount => subtotal * (couponDiscountPercent / 100.0);
  double get deliveryCharge =>
      subtotal >= settings.freeDeliveryThreshold ? 0 : settings.deliveryCharge;

  double deliveryChargeForAddress(Address? address) {
    if (subtotal >= settings.freeDeliveryThreshold) return 0.0;
    if (address == null || address.district.isEmpty) {
      return settings.deliveryCharge;
    }
    final isDhaka = address.district.trim().toLowerCase() == 'dhaka';
    return isDhaka ? 80.0 : 120.0;
  }

  double get cashbackEarned => (subtotal * (settings.cashbackPercentage / 100.0))
      .clamp(0.0, settings.maxCashbackAmount)
      .toDouble();
  double get cashbackUsed {
    if (!cashbackEnabled) return 0.0;
    if (walletBalance <= 0) return 0.0;
    double allowed = (subtotal * (settings.cashbackPercentage / 100.0))
        .clamp(0, settings.maxCashbackAmount)
        .toDouble();
    return allowed > walletBalance ? walletBalance : allowed;
  }

  double get taxAmount => (subtotal - discountAmount) * (settings.taxRate / 100.0);

  double get totalPrice =>
      subtotal - discountAmount - cashbackUsed + deliveryCharge + taxAmount;

  double totalPriceForAddress(Address? address) =>
      subtotal -
      discountAmount -
      cashbackUsed +
      deliveryChargeForAddress(address) +
      taxAmount;

  bool get requiresPrescription =>
      items.any((item) => item.product.requiresPrescription);

  @override
  List<Object?> get props => [
    items,
    couponCode,
    couponDiscountPercent,
    couponMinSpend,
    cashbackEnabled,
    selectedPaymentMethod,
    hasAttachedPrescription,
    prescriptionId,
    walletBalance,
    settings,
  ];
}
