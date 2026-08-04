import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import 'package:equatable/equatable.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit() : super(CheckoutState(selectedDate: DateTime.now()));

  void selectAddress(String id) => emit(state.copyWith(selectedAddressId: id));
  void selectDeliveryType(String value) =>
      emit(state.copyWith(deliveryType: value));
  void selectDate(DateTime value) => emit(state.copyWith(selectedDate: value));
  void selectTimeSlot(String value) =>
      emit(state.copyWith(selectedTimeSlot: value));
  void applyCoupon(String? value) => emit(state.copyWith(appliedCoupon: value));
  void selectPayment(PaymentMethod method) =>
      emit(state.copyWith(selectedPaymentMethod: method));
}

class CheckoutState extends Equatable {
  const CheckoutState({
    this.selectedAddressId = '',
    this.deliveryType = 'express',
    this.selectedDate,
    this.selectedTimeSlot = 'Evening 5-9',
    this.appliedCoupon,
    this.selectedPaymentMethod = PaymentMethod.cod,
  });

  final String selectedAddressId;
  final String deliveryType;
  final DateTime? selectedDate;
  final String selectedTimeSlot;
  final String? appliedCoupon;
  final PaymentMethod selectedPaymentMethod;

  CheckoutState copyWith({
    String? selectedAddressId,
    String? deliveryType,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    String? appliedCoupon,
    PaymentMethod? selectedPaymentMethod,
  }) {
    return CheckoutState(
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      deliveryType: deliveryType ?? this.deliveryType,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    selectedAddressId,
    deliveryType,
    selectedDate,
    selectedTimeSlot,
    appliedCoupon,
    selectedPaymentMethod,
  ];
}
