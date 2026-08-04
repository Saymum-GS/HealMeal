part of 'search_cubit.dart';

enum SearchStatus { initial, loading, success, empty }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
  });

  final SearchStatus status;
  final String query;
  final List<Product> results;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Product>? results,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [status, query, results];
}
