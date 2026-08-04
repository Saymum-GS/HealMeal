import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/repositories.dart';
import '../../core/services.dart';
import '../../core/config.dart';
import '../../core/widgets.dart';
import '../cart/cart_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryHomeScreen extends StatefulWidget {
  const CategoryHomeScreen({super.key, required this.slug});

  final String slug;

  @override
  State<CategoryHomeScreen> createState() => _CategoryHomeScreenState();
}

class _CategoryHomeScreenState extends State<CategoryHomeScreen> {
  late Future<AppCategory?> _categoryFuture;
  late Future<QuerySnapshot> _productsFuture;

  @override
  void initState() {
    super.initState();
    _categoryFuture = getIt<CategoryRepository>().getCategoryBySlug(
      widget.slug,
    );
    _productsFuture = FirebaseFirestore.instance
        .collection('products')
        .where('categoryId', isEqualTo: widget.slug)
        .where('isAvailable', isEqualTo: true)
        .limit(20)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppCategory?>(
      future: _categoryFuture,
      builder: (context, categorySnapshot) {
        final category = categorySnapshot.data;
        final title =
            category?.name ?? widget.slug.replaceAll('-', ' ').toUpperCase();
        final icon = category?.icon ?? Icons.medication_rounded;
        final color = category?.color ?? AppColors.primary;

        return Scaffold(
          appBar: HealMealAppBar(
            title: title,
            showBack: true,
            showSearch: true,
            showCart: true,
          ),
          body: FutureBuilder<QuerySnapshot>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final products =
                  snapshot.data?.docs
                      .map((doc) {
                        try {
                          return Product.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          );
                        } catch (e) {
                          return null;
                        }
                      })
                      .whereType<Product>()
                      .toList() ??
                  [];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140.h,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.all(20.w),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.h1.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Icon(
                                  icon,
                                  size: 48.w,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SectionHeader(title: 'Medicines', showSeeAll: false),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 304,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                          onAddToCart: () =>
                              context.read<CartCubit>().addItem(product),
                        );
                      }, childCount: products.length),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
