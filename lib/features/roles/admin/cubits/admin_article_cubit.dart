import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';

abstract class AdminArticleState extends Equatable {
  const AdminArticleState();
  @override
  List<Object?> get props => [];
}

class AdminArticleInitial extends AdminArticleState {}

class AdminArticleLoading extends AdminArticleState {}

class AdminArticleLoaded extends AdminArticleState {
  final List<Article> articles;
  const AdminArticleLoaded(this.articles);
  @override
  List<Object?> get props => [articles];
}

class AdminArticleError extends AdminArticleState {
  final String message;
  const AdminArticleError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminArticleCubit extends Cubit<AdminArticleState> {
  final ArticleRepository _repository;
  StreamSubscription? _subscription;

  AdminArticleCubit(this._repository) : super(AdminArticleInitial());

  void startWatching() {
    emit(AdminArticleLoading());
    _subscription?.cancel();
    _subscription = _repository.watchAllArticles().listen(
      (articles) {
        emit(AdminArticleLoaded(articles));
      },
      onError: (e) {
        emit(AdminArticleError(e.toString()));
      },
    );
  }

  Future<void> updateArticleStatus(Article article, String status) async {
    try {
      await _repository.updateArticle(article.copyWith(status: status));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteArticle(String id) async {
    try {
      await _repository.deleteArticle(id);
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
