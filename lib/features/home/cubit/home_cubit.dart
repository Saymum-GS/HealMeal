import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final ArticleRepository _articleRepository;
  final SettingsRepository _settingsRepository;
  final ProductRepository _productRepository;

  HomeCubit({
    required ArticleRepository articleRepository,
    required SettingsRepository settingsRepository,
    required ProductRepository productRepository,
  }) : _articleRepository = articleRepository,
       _settingsRepository = settingsRepository,
       _productRepository = productRepository,
       super(HomeState()) {
    load();
  }

  /// Fallback constructor used when Firebase/ServiceLocator failed to init.
  /// Returns an empty HomeCubit that shows an empty but valid home screen.
  HomeCubit.empty()
    : _articleRepository = ArticleRepository(),
      _settingsRepository = SettingsRepository(),
      _productRepository = ProductRepository(),
      super(HomeState(loading: false));

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh && state.loading) return;
    emit(state.copyWith(loading: true));
    try {
      // Load all CMS data in parallel with one-shot reads, catching individual errors
      final results = await Future.wait<dynamic>([
        _articleRepository.getFeaturedArticles().catchError((_) => <Article>[]),
        _articleRepository.getDailyTip().catchError((_) => null),
        _settingsRepository.getSettings(),
        _loadFeaturedProducts(),
        _productRepository
            .getProductsByCategory(categoryId: 'diabetes_care', limit: 10)
            .catchError((_) => (products: <Product>[], lastDoc: null)),
        _productRepository
            .getProductsByCategory(
              categoryId: 'cardiovascular_system',
              limit: 10,
            )
            .catchError((_) => (products: <Product>[], lastDoc: null)),
        _productRepository
            .getProductsByCategory(
              categoryId: 'dermatological_preparations',
              limit: 10,
            )
            .catchError((_) => (products: <Product>[], lastDoc: null)),
        _productRepository
            .getProductsByCategory(categoryId: 'vitamins_minerals', limit: 10)
            .catchError((_) => (products: <Product>[], lastDoc: null)),
        _productRepository
            .getProductsByPrice(maxPrice: 100, limit: 10)
            .catchError((_) => (products: <Product>[], lastDoc: null)),
      ]);

      emit(
        state.copyWith(
          articles: results[0] as List<Article>,
          dailyTip: results[1] as Article?,
          settings: results[2] as PlatformSettings,
          featuredProducts: results[3] as List<Product>,
          diabetesProducts:
              (results[4]
                      as ({List<Product> products, DocumentSnapshot? lastDoc}))
                  .products,
          heartProducts:
              (results[5]
                      as ({List<Product> products, DocumentSnapshot? lastDoc}))
                  .products,
          skinCareProducts:
              (results[6]
                      as ({List<Product> products, DocumentSnapshot? lastDoc}))
                  .products,
          vitaminProducts:
              (results[7]
                      as ({List<Product> products, DocumentSnapshot? lastDoc}))
                  .products,
          under100Products:
              (results[8]
                      as ({List<Product> products, DocumentSnapshot? lastDoc}))
                  .products,
          loading: false,
        ),
      );
    } catch (e, st) {
      debugPrint('HomeCubit.load error: $e\n$st');
      // Try to at least load settings
      try {
        final settings = await _settingsRepository.getSettings();
        emit(state.copyWith(settings: settings, loading: false));
      } catch (_) {
        emit(state.copyWith(loading: false));
      }
    }
  }

  Future<List<Product>> _loadFeaturedProducts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      return snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }
}
