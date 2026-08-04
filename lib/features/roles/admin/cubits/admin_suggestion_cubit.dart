import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/repositories.dart';

class AdminSuggestionState extends Equatable {
  const AdminSuggestionState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ProductSuggestion> suggestions;
  final bool isLoading;
  final String? error;

  AdminSuggestionState copyWith({
    List<ProductSuggestion>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return AdminSuggestionState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [suggestions, isLoading, error];
}

class AdminSuggestionCubit extends Cubit<AdminSuggestionState> {
  AdminSuggestionCubit({required SuggestionRepository suggestionRepository})
    : _suggestionRepository = suggestionRepository,
      super(AdminSuggestionState());

  final SuggestionRepository _suggestionRepository;
  StreamSubscription<List<ProductSuggestion>>? _suggestionSubscription;

  void startWatchingSuggestions() {
    if (_suggestionSubscription != null) return;
    emit(state.copyWith(isLoading: true));
    _suggestionSubscription = _suggestionRepository.watchSuggestions().listen(
      (suggestions) {
        emit(state.copyWith(suggestions: suggestions, isLoading: false));
      },
      onError: (e) {
        debugPrint("Error watching suggestions: $e");
        emit(state.copyWith(error: e.toString(), isLoading: false));
      },
    );
  }

  @override
  Future<void> close() {
    _suggestionSubscription?.cancel();
    return super.close();
  }

  Future<void> deleteSuggestion(String id) async {
    try {
      await _suggestionRepository.deleteSuggestion(id);
    } catch (e) {
      debugPrint("Error deleting suggestion: $e");
      rethrow;
    }
  }
}
