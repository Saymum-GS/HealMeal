import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import 'package:equatable/equatable.dart';
import '../../../core/repositories.dart';
import '../../../core/services/groq_service.dart';

enum SearchStatus { initial, loading, success, empty, error }

class SearchFilters extends Equatable {
  const SearchFilters({
    this.categoryId,
    this.requiresPrescription,
    this.minPrice,
    this.maxPrice,
  });

  final String? categoryId;
  final bool? requiresPrescription;
  final double? minPrice;
  final double? maxPrice;

  @override
  List<Object?> get props => [
    categoryId,
    requiresPrescription,
    minPrice,
    maxPrice,
  ];

  SearchFilters copyWith({
    String? categoryId,
    bool? requiresPrescription,
    double? minPrice,
    double? maxPrice,
    bool clearCategoryId = false,
    bool clearRequiresPrescription = false,
  }) {
    return SearchFilters(
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      requiresPrescription: clearRequiresPrescription
          ? null
          : (requiresPrescription ?? this.requiresPrescription),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.aiNote = '',
    this.results = const [],
    this.recentSearches = const [],
    this.filters = const SearchFilters(),
  });

  final SearchStatus status;
  final String query;
  final String aiNote;
  final List<Product> results;
  final List<String> recentSearches;
  final SearchFilters filters;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    String? aiNote,
    List<Product>? results,
    List<String>? recentSearches,
    SearchFilters? filters,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      aiNote: aiNote ?? this.aiNote,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    aiNote,
    results,
    recentSearches,
    filters,
  ];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required this.repository,
    required this.historyRepository,
    required this.groqService,
  }) : super(SearchState()) {
    loadHistory();
  }

  final ProductRepository repository;
  final SearchHistoryRepository historyRepository;
  final GroqService groqService;
  Timer? _debounce;

  Future<void> loadHistory() async {
    final history = await historyRepository.getHistory();
    emit(state.copyWith(recentSearches: history));
  }

  void search(String query) {
    if (query.trim().isEmpty) {
      _debounce?.cancel();
      emit(
        state.copyWith(
          status: SearchStatus.initial,
          query: '',
          results: [],
          aiNote: '',
        ),
      );
      return;
    }

    _debounce?.cancel();
    emit(state.copyWith(status: SearchStatus.loading, query: query));

    _debounce = Timer(Duration(milliseconds: 500), () async {
      try {
        if (isClosed) return;
        await historyRepository.addSearch(query);
        final history = await historyRepository.getHistory();

        // 1. Local/Firestore Prefix Search
        final localResultsRecord = await repository.searchProducts(query);
        List<Product> finalResults = List.from(localResultsRecord.products);
        String note = '';

        // 2. AI interpretation if natural language (or if local results are empty and it's multi-word)
        final isNaturalLanguage =
            query.trim().split(' ').length >= 3 ||
            [
              'fever',
              'pain',
              'cold',
              'cough',
              'জ্বর',
              'ব্যথা',
              'সর্দি',
            ].any((w) => query.toLowerCase().contains(w));

        if (isNaturalLanguage) {
          final aiResult = await groqService.interpretSearchQuery(query);
          if (aiResult != null && aiResult.generics.isNotEmpty) {
            note = aiResult.note;
            // Search Firestore using the extracted generic names
            for (final generic in aiResult.generics) {
              final aiFilteredRecord = await repository.searchProducts(generic);
              finalResults.addAll(aiFilteredRecord.products);
            }
            // Remove duplicates
            final seen = <String>{};
            finalResults = finalResults.where((p) => seen.add(p.id)).toList();
          }
        }

        final filteredResults = _applyFilters(finalResults);

        if (isClosed) return;

        emit(
          state.copyWith(
            status: filteredResults.isEmpty
                ? SearchStatus.empty
                : SearchStatus.success,
            query: query,
            results: filteredResults,
            recentSearches: history,
            aiNote: note,
          ),
        );
      } catch (e) {
        if (isClosed) return;
        emit(state.copyWith(status: SearchStatus.error));
      }
    });
  }

  void updateFilters(SearchFilters filters) {
    emit(state.copyWith(filters: filters));
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    final f = state.filters;
    return products.where((p) {
      if (f.categoryId != null && p.categoryId != f.categoryId) {
        return false;
      }
      if (f.requiresPrescription != null &&
          p.requiresPrescription != f.requiresPrescription) {
        return false;
      }
      if (f.minPrice != null && p.effectivePrice < f.minPrice!) return false;
      if (f.maxPrice != null && p.effectivePrice > f.maxPrice!) return false;
      return true;
    }).toList();
  }

  Future<void> clearHistory() async {
    await historyRepository.clearHistory();
    emit(state.copyWith(recentSearches: []));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
