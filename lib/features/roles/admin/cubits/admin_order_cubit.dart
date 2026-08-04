import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';

class AdminOrderState extends Equatable {
  const AdminOrderState({
    this.allOrders = const [],
    this.hasMoreOrders = true,
    this.lastOrderDoc,
    this.isFetchingMoreOrders = false,
    this.currentStatusFilter,
    this.isLoading = false,
    this.error,
  });

  final List<AppOrder> allOrders;
  final bool hasMoreOrders;
  final DocumentSnapshot? lastOrderDoc;
  final bool isFetchingMoreOrders;
  final OrderStatus? currentStatusFilter;
  final bool isLoading;
  final String? error;

  AdminOrderState copyWith({
    List<AppOrder>? allOrders,
    bool? hasMoreOrders,
    DocumentSnapshot? lastOrderDoc,
    bool clearLastOrderDoc = false,
    bool? isFetchingMoreOrders,
    OrderStatus? currentStatusFilter,
    bool clearStatusFilter = false,
    bool? isLoading,
    String? error,
  }) {
    return AdminOrderState(
      allOrders: allOrders ?? this.allOrders,
      hasMoreOrders: hasMoreOrders ?? this.hasMoreOrders,
      lastOrderDoc: clearLastOrderDoc
          ? null
          : (lastOrderDoc ?? this.lastOrderDoc),
      isFetchingMoreOrders: isFetchingMoreOrders ?? this.isFetchingMoreOrders,
      currentStatusFilter: clearStatusFilter
          ? null
          : (currentStatusFilter ?? this.currentStatusFilter),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    allOrders,
    hasMoreOrders,
    lastOrderDoc,
    isFetchingMoreOrders,
    currentStatusFilter,
    isLoading,
    error,
  ];
}

class AdminOrderCubit extends Cubit<AdminOrderState> {
  AdminOrderCubit({required OrderRepository orderRepository})
    : _orderRepository = orderRepository,
      super(AdminOrderState());

  final OrderRepository _orderRepository;

  Future<void> fetchOrders({bool refresh = false, OrderStatus? status}) async {
    if (refresh) {
      emit(
        state.copyWith(
          isLoading: true,
          clearLastOrderDoc: true,
          hasMoreOrders: true,
          allOrders: [],
          currentStatusFilter: status,
          clearStatusFilter: status == null,
        ),
      );
    } else if (state.allOrders.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }

    try {
      Query query = FirebaseFirestore.instance.collection('orders');
      if (state.currentStatusFilter != null) {
        query = query.where(
          'status',
          isEqualTo: state.currentStatusFilter!.name,
        );
      }
      query = query.orderBy('placedAt', descending: true).limit(20);

      final snap = await query.get();

      final orders = snap.docs
          .map(
            (doc) =>
                AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
      emit(
        state.copyWith(
          isLoading: false,
          allOrders: orders,
          lastOrderDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
          hasMoreOrders: snap.docs.length >= 20,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadMoreOrders() async {
    if (!state.hasMoreOrders || state.isFetchingMoreOrders || state.isLoading) {
      return;
    }

    emit(state.copyWith(isFetchingMoreOrders: true));

    try {
      Query query = FirebaseFirestore.instance.collection('orders');
      if (state.currentStatusFilter != null) {
        query = query.where(
          'status',
          isEqualTo: state.currentStatusFilter!.name,
        );
      }
      query = query.orderBy('placedAt', descending: true).limit(20);

      if (state.lastOrderDoc != null) {
        query = query.startAfterDocument(state.lastOrderDoc!);
      }

      final snap = await query.get();
      final newOrders = snap.docs
          .map(
            (doc) =>
                AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      emit(
        state.copyWith(
          isFetchingMoreOrders: false,
          allOrders: [...state.allOrders, ...newOrders],
          lastOrderDoc: snap.docs.isNotEmpty
              ? snap.docs.last
              : state.lastOrderDoc,
          hasMoreOrders: snap.docs.length >= 20,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isFetchingMoreOrders: false, error: e.toString()));
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final int idx = state.allOrders.indexWhere((o) => o.id == orderId);
    List<AppOrder>? previousOrders;

    if (idx != -1) {
      previousOrders = List<AppOrder>.from(state.allOrders);
      final newOrders = List<AppOrder>.from(state.allOrders);
      newOrders[idx] = newOrders[idx].copyWith(status: status);
      emit(state.copyWith(allOrders: newOrders));
    }

    try {
      await _orderRepository.updateOrderStatus(orderId, status);
    } catch (e) {
      if (previousOrders != null) {
        emit(state.copyWith(allOrders: previousOrders, error: e.toString()));
      } else {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> updateAdvancedOrderFields(
    String orderId,
    String paymentStatus,
    String refundStatus,
    String fulfillmentNotes,
    String? deliveryAssignment,
  ) async {
    final int idx = state.allOrders.indexWhere((o) => o.id == orderId);
    List<AppOrder>? previousOrders;

    if (idx != -1) {
      previousOrders = List<AppOrder>.from(state.allOrders);
      final newOrders = List<AppOrder>.from(state.allOrders);
      newOrders[idx] = newOrders[idx].copyWith(
        paymentStatus: paymentStatus,
        refundStatus: refundStatus,
        fulfillmentNotes: fulfillmentNotes,
        deliveryAssignment: deliveryAssignment,
      );
      emit(state.copyWith(allOrders: newOrders));
    }

    try {
      await _orderRepository.updateAdvancedOrderFields(
        orderId,
        paymentStatus,
        refundStatus,
        fulfillmentNotes,
        deliveryAssignment,
      );
    } catch (e) {
      if (previousOrders != null) {
        emit(state.copyWith(allOrders: previousOrders, error: e.toString()));
      } else {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }
}
