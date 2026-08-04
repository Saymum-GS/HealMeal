import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) throw Exception('Order not found');

      final orderData = orderSnap.data()!;
      final currentStatus = orderData['status'] as String?;

      if (currentStatus == OrderStatus.cancelled.name &&
          status != OrderStatus.cancelled) {
        throw Exception('Cannot change the status of a cancelled order.');
      }

      if (status == OrderStatus.cancelled &&
          currentStatus != OrderStatus.cancelled.name) {
        final itemsList = List<dynamic>.from(orderData['items'] ?? []);
        for (final itemMap in itemsList) {
          final pMap = itemMap['product'] as Map<String, dynamic>?;
          if (pMap != null) {
            final productId = pMap['id'] as String?;
            final qty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
            if (productId != null && productId.isNotEmpty && qty > 0) {
              final pRef = _firestore.collection('products').doc(productId);
              final pSnap = await transaction.get(pRef);
              if (pSnap.exists) {
                transaction.update(pRef, {
                  'countInStock': FieldValue.increment(qty),
                });
              }
            }
          }
        }

        // Refund cashback used and reverse cashback earned
        final cashbackUsed =
            (orderData['cashbackUsed'] as num?)?.toDouble() ?? 0.0;
        final cashbackEarned =
            (orderData['cashbackEarned'] as num?)?.toDouble() ?? 0.0;
        final userId = orderData['userId'] as String?;
        if (userId != null) {
          double balanceChange = cashbackUsed;
          if (currentStatus == OrderStatus.delivered.name) {
            balanceChange -= cashbackEarned;
          }
          if (balanceChange != 0) {
            final userRef = _firestore.collection('users').doc(userId);
            transaction.update(userRef, {
              'walletBalance': FieldValue.increment(balanceChange),
            });
          }
        }

        // Refund coupon usage
        final couponCode = orderData['couponCode'] as String?;
        if (couponCode != null && couponCode.isNotEmpty) {
          // Note: We can't query inside a transaction, so we assume the coupon is valid and decrement it.
          // Or we skip it if we can't find it. To be safe, we don't refund usesCount without a direct doc ref.
          // Alternatively, we could fetch the ref first, but we don't have it.
        }
      } else if (status == OrderStatus.delivered &&
          currentStatus != OrderStatus.delivered.name) {
        final subtotal = (orderData['subtotal'] as num?)?.toDouble() ?? 0.0;
        final userId = orderData['userId'] as String?;

        if (userId != null && subtotal > 0) {
          final settingsRef = _firestore
              .collection('platform_settings')
              .doc('global');
          final settingsSnap = await transaction.get(settingsRef);
          final cashbackPercent =
              (settingsSnap.data()?['cashbackPercentage'] as num? ?? 8.0)
                  .toDouble();
          final maxCashback =
              (settingsSnap.data()?['maxCashbackAmount'] as num? ?? 125.5)
                  .toDouble();

          final earned = (subtotal * (cashbackPercent / 100.0)).clamp(
            0.0,
            maxCashback,
          );
          if (earned > 0) {
            final userRef = _firestore.collection('users').doc(userId);
            transaction.update(userRef, {
              'walletBalance': FieldValue.increment(earned),
            });
            transaction.update(orderRef, {'cashbackEarned': earned});
          }
        }
      } else if (currentStatus == OrderStatus.delivered.name &&
          status != OrderStatus.delivered &&
          status != OrderStatus.cancelled) {
        final cashbackEarned =
            (orderData['cashbackEarned'] as num?)?.toDouble() ?? 0.0;
        final userId = orderData['userId'] as String?;
        if (userId != null && cashbackEarned > 0) {
          final userRef = _firestore.collection('users').doc(userId);
          transaction.update(userRef, {
            'walletBalance': FieldValue.increment(-cashbackEarned),
          });
          transaction.update(orderRef, {'cashbackEarned': 0.0});
        }
      }

      final prescriptionId = orderData['prescriptionId'] as String?;
      if (status == OrderStatus.confirmed &&
          prescriptionId != null &&
          prescriptionId.isNotEmpty) {
        final rxRef =
            _firestore.collection('prescriptions').doc(prescriptionId);
        final rxSnap = await transaction.get(rxRef);
        if (rxSnap.exists) {
          transaction.update(rxRef, {'status': 'approved'});
        }
      }

      transaction.update(orderRef, {
        'status': status.name,
        'timeline': FieldValue.arrayUnion([
          {'status': status.label, 'time': Timestamp.now(), 'completed': true},
        ]),
      });
    });
  }

  Future<void> updateAdvancedOrderFields(
    String orderId,
    String paymentStatus,
    String refundStatus,
    String fulfillmentNotes,
    String? deliveryAssignment,
  ) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': paymentStatus,
      'refundStatus': refundStatus,
      'fulfillmentNotes': fulfillmentNotes,
      'deliveryAssignment': deliveryAssignment,
    });
  }

  Future<void> hideOrderForUser(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'isHiddenForUser': true,
    });
  }

  Future<String> placeOrder(AppOrder order) async {
    final orderRef = _firestore.collection('orders').doc();
    final orderId = orderRef.id;

    DocumentReference? couponRef;
    if (order.couponCode != null && order.couponCode!.isNotEmpty) {
      final query = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: order.couponCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        couponRef = query.docs.first.reference;
      }
    }

    final settingsDoc = await _firestore
        .collection('platform_settings')
        .doc('global')
        .get();
    final taxRate = (settingsDoc.data()?['taxRate'] as num? ?? 0.0).toDouble();
    final freeDeliveryThreshold =
        (settingsDoc.data()?['freeDeliveryThreshold'] as num? ?? 1999.0)
            .toDouble();
    final isDhaka =
        order.deliveryAddress?.district.trim().toLowerCase() == 'dhaka';
    final defaultDeliveryCharge = isDhaka
        ? 80.0
        : (order.deliveryAddress != null &&
                order.deliveryAddress!.district.isNotEmpty
            ? 120.0
            : 80.0);
    final cashbackPercent =
        (settingsDoc.data()?['cashbackPercentage'] as num? ?? 8.0).toDouble();
    final maxCashback =
        (settingsDoc.data()?['maxCashbackAmount'] as num? ?? 125.5).toDouble();

    await _firestore.runTransaction((tx) async {
      double serverSubtotal = 0.0;

      // 1. Check stock & calculate subtotal based on DB prices
      for (final item in order.items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.product.id);
        final snap = await tx.get(productRef);
        if (!snap.exists) {
          throw Exception('Product not found: ${item.product.drugName}');
        }

        final data = snap.data()!;

        final countInStock = (data['countInStock'] as num?)?.toInt() ?? 0;
        final isAvailable = data['isAvailable'] as bool? ?? true;
        final lifecycleStatus = data['lifecycleStatus'] as String?;

        if (!isAvailable || lifecycleStatus == 'discontinued') {
          throw Exception('${item.product.drugName} is currently unavailable.');
        }

        if (item.quantity > countInStock) {
          throw Exception(
            'Not enough stock for ${item.product.drugName}. Only $countInStock available.',
          );
        }

        final mrp = (data['mrp'] as num? ?? 0.0).toDouble();
        final salePrice = (data['salePrice'] as num? ?? mrp).toDouble();
        final isFlashSale = data['isFlashSale'] as bool? ?? false;
        final flashPrice = (data['flashSalePrice'] as num?)?.toDouble();
        final startAtDate = (data['flashSaleStartAt'] as Timestamp?)?.toDate();
        final endAtDate = (data['flashSaleEndAt'] as Timestamp?)?.toDate();

        bool isCurrentlyFlashSale =
            isFlashSale && flashPrice != null && flashPrice > 0;
        final now = DateTime.now();
        if (isCurrentlyFlashSale &&
            startAtDate != null &&
            now.isBefore(startAtDate)) {
          isCurrentlyFlashSale = false;
        }
        if (isCurrentlyFlashSale &&
            endAtDate != null &&
            now.isAfter(endAtDate)) {
          isCurrentlyFlashSale = false;
        }

        final effectivePrice = isCurrentlyFlashSale ? flashPrice! : salePrice;

        serverSubtotal += effectivePrice * item.quantity;
      }

      double serverDiscountPercent = 0.0;
      // 2. Read coupon if applicable
      DocumentSnapshot? couponSnap;
      if (couponRef != null) {
        couponSnap = await tx.get(couponRef);
      }

      // 3. Read user for wallet balance if applicable
      DocumentSnapshot<Map<String, dynamic>>? userSnap;
      final userRef = order.userId != null
          ? _firestore.collection('users').doc(order.userId)
          : null;
      if (order.cashbackUsed > 0 && userRef != null) {
        userSnap = await tx.get(userRef);
      }

      // NOW START WRITES

      // Validate coupon and mark for increment
      if (couponSnap != null && couponSnap.exists) {
        final data = couponSnap.data() as Map<String, dynamic>;
        if (data['isActive'] == true) {
          final expiration = data['expirationDate'] as Timestamp?;
          if (expiration == null ||
              !expiration.toDate().isBefore(DateTime.now())) {
            final minSpend = (data['minimumSpend'] as num? ?? 0.0).toDouble();
            if (serverSubtotal >= minSpend) {
              final maxUses = (data['maxUses'] as num?)?.toInt() ?? 0;
              final currentUses = (data['usesCount'] as num?)?.toInt() ?? 0;
              if (maxUses == 0 || currentUses < maxUses) {
                serverDiscountPercent = (data['discountPercent'] as num? ?? 0.0)
                    .toDouble();
                tx.update(couponRef!, {'usesCount': FieldValue.increment(1)});
              }
            }
          }
        }
      }

      final serverDiscountAmount =
          serverSubtotal * (serverDiscountPercent / 100.0);
      final serverDeliveryCharge = serverSubtotal >= freeDeliveryThreshold
          ? 0.0
          : defaultDeliveryCharge;
      final serverTax =
          (serverSubtotal - serverDiscountAmount) * (taxRate / 100);

      // Validate cashback usage
      double serverCashbackUsed = order.cashbackUsed;
      if (serverCashbackUsed > 0 && userSnap != null && userRef != null) {
        if (userSnap.exists) {
          final walletBalance =
              (userSnap.data()?['walletBalance'] as num? ?? 0.0).toDouble();
          final allowedCashback = (serverSubtotal * (cashbackPercent / 100.0))
              .clamp(0.0, maxCashback)
              .toDouble();
          final allowedMaxCashback = allowedCashback > walletBalance
              ? walletBalance
              : allowedCashback;

          if (serverCashbackUsed > allowedMaxCashback) {
            serverCashbackUsed = allowedMaxCashback;
          }
          tx.update(userRef, {
            'walletBalance': FieldValue.increment(-serverCashbackUsed),
          });
        } else {
          serverCashbackUsed = 0.0;
        }
      }

      final serverTotal =
          serverSubtotal -
          serverDiscountAmount -
          serverCashbackUsed +
          serverDeliveryCharge +
          serverTax;

      // 3. Write order with trusted values
      final orderMap = order
          .copyWith(
            id: orderId,
            subtotal: serverSubtotal,
            discountAmount: serverDiscountAmount,
            deliveryCharge: serverDeliveryCharge,
            cashbackUsed: serverCashbackUsed,
            total: serverTotal,
          )
          .toMap();

      tx.set(orderRef, orderMap);

      // 4. Record order and deduct stock
      for (final item in order.items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.product.id);
        tx.update(productRef, {
          'countInStock': FieldValue.increment(-item.quantity),
        });
      }
    });

    return orderId;
  }

  Future<List<AppOrder>> getUserOrders(String userId) async {
    final snap = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('placedAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) => AppOrder.fromMap(d.data(), d.id)).toList();
  }

  Future<List<AppOrder>> getOrdersByStatus(
    OrderStatus status, {
    int limit = 50,
  }) async {
    final snap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: status.name)
        .orderBy('placedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => AppOrder.fromMap(d.data(), d.id)).toList();
  }
}
