import 'package:equatable/equatable.dart';

import '../../../core/models.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.featuredProducts = const [],
    this.diabetesProducts = const [],
    this.heartProducts = const [],
    this.skinCareProducts = const [],
    this.vitaminProducts = const [],
    this.under100Products = const [],
    this.articles = const [],
    this.dailyTip,
    this.settings,
  });

  final bool loading;
  final List<Product> featuredProducts;
  final List<Article> articles;
  final Article? dailyTip;
  final PlatformSettings? settings;
  final List<Product> diabetesProducts;
  final List<Product> heartProducts;
  final List<Product> skinCareProducts;
  final List<Product> vitaminProducts;
  final List<Product> under100Products;

  HomeState copyWith({
    bool? loading,
    List<Product>? featuredProducts,
    List<Product>? diabetesProducts,
    List<Product>? heartProducts,
    List<Product>? skinCareProducts,
    List<Product>? vitaminProducts,
    List<Product>? under100Products,
    List<Article>? articles,
    Article? dailyTip,
    PlatformSettings? settings,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      diabetesProducts: diabetesProducts ?? this.diabetesProducts,
      heartProducts: heartProducts ?? this.heartProducts,
      skinCareProducts: skinCareProducts ?? this.skinCareProducts,
      vitaminProducts: vitaminProducts ?? this.vitaminProducts,
      under100Products: under100Products ?? this.under100Products,
      articles: articles ?? this.articles,
      dailyTip: dailyTip ?? this.dailyTip,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    featuredProducts,
    diabetesProducts,
    heartProducts,
    skinCareProducts,
    vitaminProducts,
    under100Products,
    articles,
    dailyTip,
    settings,
  ];
}
