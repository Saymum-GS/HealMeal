import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';

abstract class AdminLabPackageState extends Equatable {
  const AdminLabPackageState();
  @override
  List<Object?> get props => [];
}

class AdminLabPackageInitial extends AdminLabPackageState {}

class AdminLabPackageLoading extends AdminLabPackageState {}

class AdminLabPackageLoaded extends AdminLabPackageState {
  final List<LabPackage> packages;
  const AdminLabPackageLoaded(this.packages);
  @override
  List<Object?> get props => [packages];
}

class AdminLabPackageError extends AdminLabPackageState {
  final String message;
  const AdminLabPackageError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminLabPackageCubit extends Cubit<AdminLabPackageState> {
  final LabTestRepository _repository;
  StreamSubscription? _subscription;

  AdminLabPackageCubit(this._repository) : super(AdminLabPackageInitial());

  void startWatching() {
    emit(AdminLabPackageLoading());
    _subscription?.cancel();
    _subscription = _repository.watchLabPackages().listen(
      (packages) {
        emit(AdminLabPackageLoaded(packages));
      },
      onError: (e) {
        emit(AdminLabPackageError(e.toString()));
      },
    );
  }

  Future<void> updatePackageStatus(LabPackage package, bool isActive) async {
    try {
      final updated = LabPackage(
        id: package.id,
        name: package.name,
        description: package.description,
        testIds: package.testIds,
        mrp: package.mrp,
        salePrice: package.salePrice,
        imageUrl: package.imageUrl,
        isActive: isActive,
      );
      await _repository.updateLabPackage(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePackage(String id) async {
    try {
      await _repository.deleteLabPackage(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
