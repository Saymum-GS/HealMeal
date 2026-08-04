import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models.dart';

class LabTestCubit extends Cubit<LabTestState> {
  final LabTestRepository _repository;

  LabTestCubit({required LabTestRepository repository})
    : _repository = repository,
      super(LabTestState());

  Future<void> load() async {
    emit(state.copyWith(status: LabTestStatus.loading));
    try {
      final tests = await _repository.fetchLabTests();
      final packages = await _repository.fetchLabPackages();
      emit(
        state.copyWith(
          status: LabTestStatus.loaded,
          allTests: tests,
          packages: packages,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: LabTestStatus.error, errorMessage: e.toString()),
      );
    }
  }
}

enum LabTestStatus { initial, loading, loaded, error }

class LabTestState extends Equatable {
  final LabTestStatus status;
  final List<LabTest> allTests;
  final List<LabPackage> packages;
  final String? errorMessage;

  const LabTestState({
    this.status = LabTestStatus.initial,
    this.allTests = const [],
    this.packages = const [],
    this.errorMessage,
  });

  LabTestState copyWith({
    LabTestStatus? status,
    List<LabTest>? allTests,
    List<LabPackage>? packages,
    String? errorMessage,
  }) {
    return LabTestState(
      status: status ?? this.status,
      allTests: allTests ?? this.allTests,
      packages: packages ?? this.packages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allTests, packages, errorMessage];
}
