import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models.dart';
import '../../../core/utils.dart';
import '../../../core/services.dart';
import '../../../core/repositories.dart';
import '../cart/cart_cubit.dart';
import '../checkout/checkout_cubit.dart';
import 'package:equatable/equatable.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit() : super(OrdersState(orders: []));

  static final String _lastPlacedKey = 'healmeal_last_order.id';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final LabRepository _labRepo = LabRepository();

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastPlacedAppOrderId = prefs.getString(_lastPlacedKey);
    final userId = AppSession.userId;

    if (userId == null && AppSession.currentUserRole != UserRole.admin) {
      emit(
        OrdersState(
          orders: [],
          labBookings: [],
          lastPlacedAppOrderId: lastPlacedAppOrderId,
          loaded: true,
        ),
      );
      return;
    }

    try {
      Query query = _firestore.collection('orders');

      // If not admin, only show user's own orders. Avoid orderBy to prevent missing composite index error.
      if (AppSession.currentUserRole != UserRole.admin) {
        query = query.where('userId', isEqualTo: userId);
      } else {
        query = query.orderBy('placedAt', descending: true).limit(50);
      }

      final snapshot = await query.get();

      final List<AppOrder> orders = snapshot.docs
          .map(
            (doc) =>
                AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where((o) => !o.isHiddenForUser)
          .toList();

      if (AppSession.currentUserRole != UserRole.admin) {
        orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
      }

      Query labQuery = _firestore.collection('lab_bookings');
      if (AppSession.currentUserRole != UserRole.admin) {
        labQuery = labQuery.where('userId', isEqualTo: userId);
      } else {
        labQuery = labQuery.orderBy('createdAt', descending: true).limit(50);
      }

      final labSnapshot = await labQuery.get();
      final List<LabBooking> labBookings = labSnapshot.docs
          .map(
            (doc) =>
                LabBooking.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      if (AppSession.currentUserRole != UserRole.admin) {
        labBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      emit(
        OrdersState(
          orders: orders,
          labBookings: labBookings,
          lastPlacedAppOrderId: lastPlacedAppOrderId,
          loaded: true,
        ),
      );

      // Trigger refill check after loading
      _checkRefills(orders);
    } catch (e) {
      debugPrint('Error loading orders: $e');
      emit(
        OrdersState(
          orders: [],
          labBookings: [],
          lastPlacedAppOrderId: lastPlacedAppOrderId,
          loaded: true,
        ),
      );
    }
  }

  void _checkRefills(List<AppOrder> orders) {
    if (orders.isEmpty) return;

    final now = DateTime.now();
    for (final order in orders) {
      // If order was placed 27-30 days ago and is delivered
      final diff = now.difference(order.placedAt).inDays;
      if (diff >= 27 && diff <= 30 && order.status == OrderStatus.delivered) {
        // Check if user already notified for this order recently
        // (In a real app, we'd check a 'notifications' collection)
        _createRefillNotification(order);
      }
    }
  }

  Future<void> _createRefillNotification(AppOrder order) async {
    final userId = AppSession.userId;
    if (userId == null) return;

    final notificationId = 'refill-${order.id}';
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId);

    final docSnap = await docRef.get();
    if (docSnap.exists) return;

    final notification = AppNotification(
      id: notificationId,
      title: 'Time for Refill!',
      body:
          'Your medicines from order ${order.id} might be running out. Would you like to reorder?',
      time: DateTime.now(),
      type: 'refill',
    );

    try {
      // Save to Firestore
      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint('Failed to create refill notification: $e');
    }
  }

  AppOrder? get lastPlacedAppOrder {
    final String? id = state.lastPlacedAppOrderId;
    if (id == null || id.isEmpty) return null;
    return findById(id);
  }

  AppOrder? findById(String id) {
    final String normalized = id.replaceAll('#', '').trim().toUpperCase();
    for (final AppOrder order in state.orders) {
      if (order.id.replaceAll('#', '').trim().toUpperCase() == normalized) {
        return order;
      }
    }
    return null;
  }

  Future<AppOrder> placeOrder({
    required CartState cartState,
    required CheckoutState checkoutState,
    required Address deliveryAddress,
  }) async {
    final DateTime placedAt = DateTime.now();
    final settings = await getIt<SettingsRepository>().getSettings();
    final userId = AppSession.userId;
    if (userId == null) {
      throw Exception('User must be logged in to place an order.');
    }

    final double subtotal = cartState.items.fold(
      0.0,
      (num acc, item) => acc + item.subtotal,
    );
    final double discount = _calculateDiscount(cartState, subtotal);
    final bool isDhaka =
        deliveryAddress.district.trim().toLowerCase() == 'dhaka';
    final double baseFee = isDhaka ? 80.0 : 120.0;
    final double deliveryCharge = subtotal >= settings.freeDeliveryThreshold
        ? 0
        : baseFee;

    final double tax = (subtotal - discount) * (settings.taxRate / 100);
    final double total = subtotal - discount + deliveryCharge + tax;

    final AppOrder order = AppOrder(
      id: '', // Will be assigned by OrderRepository
      status: OrderStatus.placed,
      paymentMethod: checkoutState.selectedPaymentMethod,
      paymentStatus: checkoutState.selectedPaymentMethod == PaymentMethod.cod
          ? 'pending'
          : 'pending_manual_confirmation',
      items: cartState.items
          .map(
            (CartEntry item) => AppOrderItem(
              id: 'oi-${placedAt.microsecondsSinceEpoch}-${item.product.id}',
              product: item.product,
              quantity: item.quantity,
            ),
          )
          .toList(),
      subtotal: subtotal,
      discountAmount: discount,
      deliveryCharge: deliveryCharge,
      total: total - cartState.cashbackUsed,
      placedAt: placedAt,
      deliveryAddress: deliveryAddress,
      timeline: _buildTimeline(placedAt, OrderStatus.placed),
      userId: userId,
      customerName: deliveryAddress.recipientName,
      customerPhone: deliveryAddress.phoneNumber,
      couponCode: cartState.couponCode,
      cashbackUsed: cartState.cashbackUsed,
      deliveryTimeSlot: checkoutState.selectedTimeSlot,
      prescriptionId: cartState.prescriptionId,
    );

    try {
      final orderId = await getIt<OrderRepository>().placeOrder(order);

      final docSnap = await _firestore.collection('orders').doc(orderId).get();
      final AppOrder finalOrder = AppOrder.fromMap(docSnap.data()!, docSnap.id);

      emit(
        state.copyWith(
          orders: [finalOrder, ...state.orders],
          lastPlacedAppOrderId: finalOrder.id,
          loaded: true,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastPlacedKey, finalOrder.id);

      return finalOrder;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return Future.error(e);
    }
  }

  double _calculateDiscount(CartState cartState, double subtotal) {
    return subtotal * (cartState.couponDiscountPercent / 100.0);
  }

  List<AppOrderTimeline> _buildTimeline(DateTime placedAt, OrderStatus status) {
    final Map<OrderStatus, int> offsets = {
      OrderStatus.placed: 0,
      OrderStatus.confirmed: 2,
      OrderStatus.processing: 4,
      OrderStatus.outForDelivery: 12,
      OrderStatus.delivered: 24,
    };

    final steps = OrderStatus.values
        .where((s) => s != OrderStatus.cancelled)
        .toList();
    return steps
        .map(
          (s) => AppOrderTimeline(
            status: s.label,
            time: placedAt.add(Duration(hours: offsets[s] ?? (s.index * 2))),
            completed: s.index <= status.index,
          ),
        )
        .toList();
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final normalizedId = orderId.replaceAll('#', '').trim();
      await OrderRepository().updateOrderStatus(
        normalizedId,
        OrderStatus.cancelled,
      );
      final updatedOrders = state.orders
          .map(
            (o) =>
                o.id == orderId ? o.copyWith(status: OrderStatus.cancelled) : o,
          )
          .toList();
      emit(state.copyWith(orders: updatedOrders));
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      rethrow;
    }
  }

  Future<void> cancelLabBooking(String bookingId) async {
    try {
      await _labRepo.updateBookingStatus(bookingId, LabBookingStatus.cancelled);
      final updatedBookings = state.labBookings.map((b) {
        if (b.id == bookingId) {
          return b.copyWith(status: LabBookingStatus.cancelled);
        }
        return b;
      }).toList();
      emit(state.copyWith(labBookings: updatedBookings));
    } catch (e) {
      debugPrint('Error cancelling lab booking: $e');
      rethrow;
    }
  }

  Future<void> hideOrder(String orderId) async {
    try {
      final normalizedId = orderId.replaceAll('#', '').trim();
      await OrderRepository().hideOrderForUser(normalizedId);
      final updatedOrders = state.orders.where((o) => o.id != orderId).toList();
      emit(state.copyWith(orders: updatedOrders));
    } catch (e) {
      debugPrint('Error hiding order: $e');
      rethrow;
    }
  }
}

class OrdersState extends Equatable {
  const OrdersState({
    this.orders = const <AppOrder>[],
    this.labBookings = const <LabBooking>[],
    this.lastPlacedAppOrderId,
    this.loaded = false,
  });

  final List<AppOrder> orders;
  final List<LabBooking> labBookings;
  final String? lastPlacedAppOrderId;
  final bool loaded;

  OrdersState copyWith({
    List<AppOrder>? orders,
    List<LabBooking>? labBookings,
    String? lastPlacedAppOrderId,
    bool? loaded,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      labBookings: labBookings ?? this.labBookings,
      lastPlacedAppOrderId: lastPlacedAppOrderId ?? this.lastPlacedAppOrderId,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    orders,
    labBookings,
    lastPlacedAppOrderId,
    loaded,
  ];
}
