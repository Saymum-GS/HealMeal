import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'enums.dart';
import 'product.dart';
import 'user.dart';

class AppOrderItem extends Equatable {
  const AppOrderItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  final String id;
  final Product product;
  final int quantity;

  double get subtotal => product.effectivePrice * quantity;

  factory AppOrderItem.fromMap(Map<String, dynamic> map) {
    return AppOrderItem(
      id: map['id'] ?? '',
      product: Product.fromMap(map['product'] ?? {}),
      quantity: (map['quantity'] ?? 1).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'product': product.toMap(), 'quantity': quantity};
  }

  @override
  List<Object?> get props => <Object?>[id, product, quantity];
}

class AppOrderTimeline extends Equatable {
  const AppOrderTimeline({
    required this.status,
    required this.time,
    required this.completed,
  });

  final String status;
  final DateTime time;
  final bool completed;

  factory AppOrderTimeline.fromMap(Map<String, dynamic> map) {
    return AppOrderTimeline(
      status: map['status'] ?? '',
      time: map['time'] is DateTime
          ? map['time']
          : (map['time'] != null
                ? (map['time'] as dynamic).toDate()
                : DateTime.now()),
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status, 'time': time, 'completed': completed};
  }

  @override
  List<Object?> get props => <Object?>[status, time, completed];
}

class AppOrder extends Equatable {
  const AppOrder({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryCharge,
    required this.total,
    required this.placedAt,
    this.deliveryAddress,
    this.timeline = const [],
    this.userId,
    this.customerName,
    this.customerPhone,
    this.specialNote,
    this.couponCode,
    this.cashbackUsed = 0.0,
    this.deliveryTimeSlot,
    this.refundStatus,
    this.fulfillmentNotes,
    this.deliveryAssignment,
    this.isHiddenForUser = false,
    this.prescriptionId,
  });

  final String id;
  final String? userId;
  final String? customerName;
  final String? customerPhone;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String paymentStatus;
  final String? refundStatus;
  final String? fulfillmentNotes;
  final String? deliveryAssignment;
  final bool isHiddenForUser;
  final List<AppOrderItem> items;
  final double subtotal;
  final double discountAmount;
  final double deliveryCharge;
  final double total;
  final DateTime placedAt;
  final Address? deliveryAddress;
  final List<AppOrderTimeline> timeline;
  final String? specialNote;
  final String? couponCode;
  final double cashbackUsed;
  final String? deliveryTimeSlot;
  final String? prescriptionId;

  double get taxAmount {
    double tax = total - (subtotal - discountAmount - cashbackUsed + deliveryCharge);
    if (tax < 0.01) return 0.0;
    return double.parse(tax.toStringAsFixed(2));
  }

  String get formattedCode {
    if (id.isEmpty) return '#HM-ORDER';
    if (id.startsWith('#')) return id;
    final suffix = id.length >= 6 ? id.substring(id.length - 6) : id;
    return '#HM-${suffix.toUpperCase()}';
  }

  String get medicineNamesSummary {
    if (items.isEmpty) return 'No items';
    final names = items.map((i) => i.product.drugName).take(3).join(', ');
    if (items.length > 3) {
      return '$names (+${items.length - 3} more)';
    }
    return names;
  }

  factory AppOrder.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppOrder(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'],
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => OrderStatus.placed,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['paymentMethod'] ?? ''),
        orElse: () => PaymentMethod.cod,
      ),
      paymentStatus: map['paymentStatus'] ?? 'pending',
      refundStatus: map['refundStatus'] ?? 'none',
      fulfillmentNotes: map['fulfillmentNotes'] ?? '',
      deliveryAssignment: map['deliveryAssignment'] as String?,
      isHiddenForUser: map['isHiddenForUser'] as bool? ?? false,
      prescriptionId: map['prescriptionId'] as String?,
      items:
          (map['items'] as List<dynamic>?)
              ?.map((i) => AppOrderItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? map['discount'] ?? 0.0)
          .toDouble(),
      deliveryCharge: (map['deliveryCharge'] ?? map['deliveryFee'] ?? 0.0)
          .toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      placedAt: map['placedAt'] is DateTime
          ? map['placedAt']
          : (map['placedAt'] != null
                ? (map['placedAt'] as dynamic).toDate()
                : DateTime.now()),
      deliveryAddress: map['deliveryAddress'] != null
          ? Address.fromMap(map['deliveryAddress'] as Map<String, dynamic>)
          : null,
      timeline:
          (map['timeline'] as List<dynamic>?)
              ?.map((t) => AppOrderTimeline.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      specialNote: map['specialNote'] as String?,
      couponCode: map['couponCode'] as String?,
      cashbackUsed: (map['cashbackUsed'] ?? 0.0).toDouble(),
      deliveryTimeSlot: map['deliveryTimeSlot'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus,
      'refundStatus': refundStatus,
      'fulfillmentNotes': fulfillmentNotes,
      'deliveryAssignment': deliveryAssignment,
      'isHiddenForUser': isHiddenForUser,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'deliveryCharge': deliveryCharge,
      'total': total,
      'placedAt': placedAt,
      'deliveryAddress': deliveryAddress?.toMap(),
      'timeline': timeline.map((t) => t.toMap()).toList(),
      'specialNote': specialNote,
      'couponCode': couponCode,
      'cashbackUsed': cashbackUsed,
      'deliveryTimeSlot': deliveryTimeSlot,
      'prescriptionId': prescriptionId,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, status, total, placedAt, userId];

  AppOrder copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerPhone,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentStatus,
    String? refundStatus,
    String? fulfillmentNotes,
    String? deliveryAssignment,
    List<AppOrderItem>? items,
    double? subtotal,
    double? discountAmount,
    double? deliveryCharge,
    double? total,
    DateTime? placedAt,
    Address? deliveryAddress,
    List<AppOrderTimeline>? timeline,
    String? specialNote,
    String? couponCode,
    double? cashbackUsed,
    String? deliveryTimeSlot,
    bool? isHiddenForUser,
    String? prescriptionId,
  }) {
    return AppOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      refundStatus: refundStatus ?? this.refundStatus,
      fulfillmentNotes: fulfillmentNotes ?? this.fulfillmentNotes,
      deliveryAssignment: deliveryAssignment ?? this.deliveryAssignment,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      total: total ?? this.total,
      placedAt: placedAt ?? this.placedAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      timeline: timeline ?? this.timeline,
      specialNote: specialNote ?? this.specialNote,
      couponCode: couponCode ?? this.couponCode,
      cashbackUsed: cashbackUsed ?? this.cashbackUsed,
      deliveryTimeSlot: deliveryTimeSlot ?? this.deliveryTimeSlot,
      isHiddenForUser: isHiddenForUser ?? this.isHiddenForUser,
    );
  }
}

extension OrderStatusColor on OrderStatus {
  Color get color {
    switch (this) {
      case OrderStatus.placed:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.dispatched:
        return Colors.indigo;
      case OrderStatus.outForDelivery:
        return Colors.amber;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.failed:
        return Colors.grey;
    }
  }
}
