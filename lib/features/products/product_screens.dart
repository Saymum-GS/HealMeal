import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets.dart';
import '../../core/config.dart';
import '../../core/services.dart';
import '../../core/repositories.dart';
import '../cart/cart_cubit.dart';
import 'product_cubit.dart';
import 'wishlist_cubit.dart';

import 'package:collection/collection.dart';

import '../../core/models.dart';
import '../auth/auth_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.queryParams});

  final Map<String, String> queryParams;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductCubit>().filter(
        category: widget.queryParams['category'],
        collection: widget.queryParams['collection'],
        featured: widget.queryParams['featured'] == 'true',
        maxPrice: widget.queryParams['maxPrice'] != null
            ? double.tryParse(widget.queryParams['maxPrice']!)
            : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(
        title: 'Medicines',
        showBack: true,
        showSearch: true,
        showCart: true,
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state.loading && state.allProducts.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.allProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.w,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text('Failed to load medicines: ${state.error}'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProductCubit>().load(refresh: true),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final products = state.filteredProducts;

          return CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        '${products.length} products found',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      Spacer(),
                      _SortButton(activeSort: state.sortBy),
                    ],
                  ),
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_rounded,
                          size: 64.w,
                          color: AppColors.subtle,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No products found',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 260,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => context.push('/product/${product.id}'),
                        onAddToCart: () {
                          context.read<CartCubit>().addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.drugName} added to cart',
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    }, childCount: products.length),
                  ),
                ),
              if (state.hasMore &&
                  (state.searchQuery == null || state.searchQuery!.isEmpty))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Center(
                      child: state.isLoadingMore
                          ? CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: () =>
                                  context.read<ProductCubit>().loadMore(),
                              child: Text('Load More'),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.activeSort});
  final ProductSort activeSort;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductSort>(
      initialValue: activeSort,
      onSelected: (sort) => context.read<ProductCubit>().sort(sort),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: context.colorBorder),
          borderRadius: AppRadius.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 14.w, color: AppColors.primary),
            SizedBox(width: 6.w),
            Text(
              'Sort',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => ProductSort.values
          .map((s) => PopupMenuItem(value: s, child: Text(_getSortName(s))))
          .toList(),
    );
  }

  String _getSortName(ProductSort s) {
    switch (s) {
      case ProductSort.relevance:
        return 'Relevance';
      case ProductSort.alphabetical:
        return 'Name: A-Z';
    }
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  late Future<Product?> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProduct();
  }

  Future<Product?> _fetchProduct() async {
    final state = context.read<ProductCubit>().state;
    final cached = state.allProducts.firstWhereOrNull((p) => p.id == widget.id);
    if (cached != null) return cached;
    return getIt<ProductRepository>().getProductById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: HealMealAppBar(title: 'Loading...', showBack: true),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final product = snapshot.data;
        if (product == null) {
          return Scaffold(
            appBar: HealMealAppBar(title: 'Not Found', showBack: true),
            body: Center(child: Text('Medicine not found')),
          );
        }

        final productState = context.watch<ProductCubit>().state;
        final substitutes = productState.allProducts
            .where(
              (p) =>
                  p.genericName == product.genericName &&
                  p.dosageForm == product.dosageForm &&
                  p.id != product.id,
            )
            .take(6)
            .toList();

        return Scaffold(
          backgroundColor: context.colorBg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: context.colorSurface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: context.colorSurface,
                    padding: EdgeInsets.only(top: 80.h, bottom: 40.h),
                    child: Hero(
                      tag: 'product_image_${product.id}',
                      child: HealMealImage(
                        imageUrl: product.imageUrl,
                        productId: product.id,
                        hasImage: product.hasImage,
                        label: product.drugName,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                actions: [
                  _WishlistDetailButton(productId: product.id),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.share_outlined),
                    onPressed: () {
                      Share.share(
                        'Check out ${product.drugName} (${product.strength}) on HealMeal! \n'
                        'Price: ৳${product.effectivePrice.toStringAsFixed(2)}\n'
                        'https://healmeal.app/product/${product.id}',
                      );
                    },
                  ),
                  SizedBox(width: 16.w),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorCard,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Header --
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.drugName, style: AppTextStyles.h1),
                                Text(
                                  '${product.strength} • ${product.dosageForm.displayName}',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (product.requiresPrescription)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: AppRadius.sm,
                              ),
                              child: Text(
                                'Rx Required',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // -- Generic & Manufacturer --
                      Text(
                        product.genericName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        product.manufacturer,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.muted,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // -- Price Section --
                      _buildPriceSection(context, product),
                      SizedBox(height: 16.h),
                      _buildQuickQuantityPresets(),

                      SizedBox(height: 32.h),

                      // -- AI Assistant Section --
                      _buildAIHelper(context, product),

                      SizedBox(height: 32.h),

                      // -- Details --
                      _buildInfoSection(
                        'Dosage & Administration',
                        product.description.isNotEmpty
                            ? product.description
                            : 'Please consult your doctor for exact dosage and instructions for this medication.',
                      ),

                      SizedBox(height: 32.h),

                      // -- Substitutes --
                      if (substitutes.isNotEmpty) ...[
                        Text(
                          'Substitutes (Same Generic)',
                          style: AppTextStyles.h3,
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          height: 220.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: substitutes.length,
                            separatorBuilder: (_, __) => SizedBox(width: 12.w),
                            itemBuilder: (context, index) {
                              final item = substitutes[index];
                              return SizedBox(
                                width: 150.w,
                                child: ProductCard(
                                  product: item,
                                  onTap: () => context.pushReplacement(
                                    '/product/${item.id}',
                                  ),
                                  onAddToCart: () {
                                    context.read<CartCubit>().addItem(item);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 32.h),
                      ],

                      // -- Safety Warning --
                      _buildSafetyWarning(),
                      SizedBox(height: 120.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, product),
        );
      },
    );
  }

  Widget _buildPriceSection(BuildContext context, Product product) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.mrp > product.effectivePrice)
              Text(
                '৳${product.mrp.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.muted,
                ),
              ),
            Text(
              '৳${product.effectivePrice.toStringAsFixed(2)}',
              style: AppTextStyles.priceLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Spacer(),
        Container(
          decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: AppRadius.md,
            border: Border.all(color: context.colorBorder),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => quantity = quantity > 1 ? quantity - 1 : 1),
                icon: Icon(Icons.remove, size: 20.w),
              ),
              InkWell(
                onTap: () => showQuantitySelectorSheet(
                  context,
                  productName: product.drugName,
                  initialQuantity: quantity,
                  maxStock: product.countInStock,
                  onQuantitySelected: (newQty) =>
                      setState(() => quantity = newQty),
                ),
                borderRadius: AppRadius.sm,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '$quantity',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: Icon(Icons.add, size: 20.w),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickQuantityPresets() {
    final presets = [
      {'label': '1', 'value': 1},
      {'label': '1 Strip (10)', 'value': 10},
      {'label': '2 Strips (20)', 'value': 20},
      {'label': '1 Month (30)', 'value': 30},
      {'label': 'Box (50)', 'value': 50},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select Quantity:',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: presets.map((p) {
            final val = p['value'] as int;
            final label = p['label'] as String;
            final isSelected = quantity == val;
            return InkWell(
              onTap: () => setState(() => quantity = val),
              borderRadius: AppRadius.pill,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : context.colorSurface,
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : context.colorBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : context.colorTextPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAIHelper(BuildContext context, Product product) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Ask HealMeal AI',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Get expert guidance on how to use ${product.drugName}, its side effects, and general precautions.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colorTextSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          HealMealButton(
            label: 'Chat with AI Assistant',
            onPressed: () {
              context.go('/search?q=Tell me about ${product.drugName}&ai=true');
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3),
        SizedBox(height: 12.h),
        Text(
          content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.colorTextSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Consult a doctor before use. Always check the expiration date and do not exceed the recommended dosage.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Product product) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.colorCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.requiresPrescription) ...[
              Text(
                'Note: A valid prescription is required and will be verified during checkout.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<CartCubit>().addItemWithQuantity(
                        product,
                        quantity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to cart')),
                      );
                    },
                    child: Text('Add to Cart'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CartCubit>().addItemWithQuantity(
                        product,
                        quantity,
                      );
                      if (context.read<AuthCubit>().state
                          is AuthUnauthenticated) {
                        showGuestAccountSheet(
                          context,
                          customMessage:
                              'Sign in to complete your purchase and track your order.',
                        );
                        return;
                      }
                      context.push('/checkout');
                    },
                    child: Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistDetailButton extends StatelessWidget {
  const _WishlistDetailButton({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, state) {
        final isWishlisted = state.productIds.contains(productId);
        return IconButton(
          icon: Icon(
            isWishlisted
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isWishlisted ? AppColors.error : AppColors.textPrimary,
          ),
          onPressed: () =>
              context.read<WishlistCubit>().toggleWishlist(productId),
        );
      },
    );
  }
}

class BrandScreen extends StatelessWidget {
  const BrandScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final productState = context.watch<ProductCubit>().state;
    final products = productState.allProducts
        .where((p) => p.manufacturer.toLowerCase().contains(id.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: HealMealAppBar(title: id.toUpperCase(), showBack: true),
      body: products.isEmpty
          ? Center(child: Text('No medicines found for this brand'))
          : GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 260,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                  onAddToCart: () => context.read<CartCubit>().addItem(product),
                );
              },
            ),
    );
  }
}
