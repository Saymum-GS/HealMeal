import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models.dart';
import 'package:equatable/equatable.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchState());

  Future<void> search(String query, List<Product> allProducts) async {
    if (query.trim().isEmpty) {
      emit(SearchState());
      return;
    }
    emit(state.copyWith(status: SearchStatus.loading, query: query));
    await Future<void>.delayed(Duration(milliseconds: 300));
    final q = query.toLowerCase();
    final results = allProducts
        .where(
          (p) =>
              p.drugName.toLowerCase().contains(q) ||
              p.manufacturer.toLowerCase().contains(q),
        )
        .toList();
    emit(
      state.copyWith(
        status: results.isEmpty ? SearchStatus.empty : SearchStatus.success,
        query: query,
        results: results,
      ),
    );
  }
}
