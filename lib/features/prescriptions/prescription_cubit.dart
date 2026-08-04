import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models.dart';
import '../../core/repositories.dart';

abstract class PrescriptionState {}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionLoading extends PrescriptionState {}

class PrescriptionUploaded extends PrescriptionState {
  final AppPrescription prescription;
  PrescriptionUploaded(this.prescription);
}

class PrescriptionError extends PrescriptionState {
  final String error;
  PrescriptionError(this.error);
}

class PrescriptionCubit extends Cubit<PrescriptionState> {
  final PrescriptionRepository _repository;

  PrescriptionCubit(this._repository) : super(PrescriptionInitial());

  Future<void> uploadPrescription(
    String userId,
    String imageBase64,
    String notes,
  ) async {
    emit(PrescriptionLoading());
    try {
      final p = AppPrescription(
        id: '',
        userId: userId,
        imageBase64: imageBase64,
        notes: notes,
        createdAt: DateTime.now(),
        status: PrescriptionStatus.pending,
      );
      final id = await _repository.uploadPrescription(p);
      emit(PrescriptionUploaded(p.copyWith(id: id)));
    } catch (e) {
      emit(PrescriptionError(e.toString()));
    }
  }
}
