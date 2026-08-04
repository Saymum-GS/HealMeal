import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';

class AdminLabBookingState extends Equatable {
  const AdminLabBookingState({
    this.labBookings = const [],
    this.isLoading = false,
    this.error,
  });

  final List<LabBooking> labBookings;
  final bool isLoading;
  final String? error;

  AdminLabBookingState copyWith({
    List<LabBooking>? labBookings,
    bool? isLoading,
    String? error,
  }) {
    return AdminLabBookingState(
      labBookings: labBookings ?? this.labBookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [labBookings, isLoading, error];
}

class AdminLabBookingCubit extends Cubit<AdminLabBookingState> {
  AdminLabBookingCubit({required LabRepository labRepository})
    : _labRepository = labRepository,
      super(AdminLabBookingState());

  final LabRepository _labRepository;
  StreamSubscription<List<LabBooking>>? _labSubscription;

  void startWatchingLabBookings() {
    if (_labSubscription != null) return;
    emit(state.copyWith(isLoading: true));
    _labSubscription = _labRepository.watchBookings().listen(
      (bookings) {
        emit(state.copyWith(labBookings: bookings, isLoading: false));
      },
      onError: (e) {
        debugPrint("Error watching lab bookings: $e");
        emit(state.copyWith(error: e.toString(), isLoading: false));
      },
    );
  }

  Future<void> updateBookingStatus(
    String bookingId,
    LabBookingStatus newStatus,
  ) async {
    await _labRepository.updateBookingStatus(bookingId, newStatus);
  }

  Future<void> updateAdvancedBookingFields(
    String bookingId, {
    String? reportBase64,
    String? assignedSlot,
    String? cancellationReason,
    LabBookingStatus? status,
  }) async {
    await _labRepository.updateAdvancedBookingFields(
      bookingId,
      reportBase64: reportBase64,
      assignedSlot: assignedSlot,
      cancellationReason: cancellationReason,
      status: status,
    );
  }

  @override
  Future<void> close() {
    _labSubscription?.cancel();
    return super.close();
  }
}
