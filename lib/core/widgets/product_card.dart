import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../config.dart';
import '../models.dart';
import '../utils.dart';
import '../../features/cart/cart_cubit.dart';
import '../../features/products/wishlist_cubit.dart';
import 'images.dart';
import 'quantity_selector_sheet.dart';
import '../../features/auth/auth_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.showWishlist = true,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool showWishlist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorCard,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(color: context.colorBorder.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'product_image_${product.id}',
                      child: HealMealImage(
                        imageUrl: product.imageUrl,
                        productId: product.id,
                        hasImage: product.hasImage,
                        label: product.drugName,
                        height: double.infinity,
                        width: double.infinity,
                        borderRadius: AppRadius.md,
                        icon: Icons.medication_rounded,
                      ),
                    ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${product.discountPercent}% OFF',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                    if (product.requiresPrescription)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Rx',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                    if (showWishlist)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _WishlistButton(productId: product.id),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // Info Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.drugName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${product.strength} ${product.dosageForm.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colorTextSecondary,
                    ),
                  ),
                  Text(
                    product.genericName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontSize: 10.sp,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Price & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (product.mrp > product.effectivePrice)
                              Text(
                                AppFormatters.taka(product.mrp),
                                style: AppTextStyles.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.muted,
                                  fontSize: 11.sp,
                                ),
                              ),
                            Text(
                              AppFormatters.taka(product.effectivePrice),
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AddToCartButton(
                        product: product,
                        onAddToCart: onAddToCart,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.productId});
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
            color: isWishlisted ? AppColors.error : AppColors.muted,
            size: 20.w,
          ),
          onPressed: () {
            if (context.read<AuthCubit>().state is AuthUnauthenticated) {
              context.push('/login');
              return;
            }
            context.read<WishlistCubit>().toggleWishlist(productId);
          },
        );
      },
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.product, required this.onAddToCart});
  final Product product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final item = state.items
            .where((i) => i.product.id == product.id)
            .firstOrNull;
        final quantity = item?.quantity ?? 0;

        if (quantity > 0) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyBtn(
                  icon: Icons.remove,
                  onTap: () => context.read<CartCubit>().updateQuantity(
                    product.id,
                    quantity - 1,
                  ),
                ),
                InkWell(
                  onTap: () => showQuantitySelectorSheet(
                    context,
                    productName: product.drugName,
                    initialQuantity: quantity,
                    maxStock: product.countInStock,
                    onQuantitySelected: (newQty) {
                      context.read<CartCubit>().updateQuantity(
                            product.id,
                            newQty,
                          );
                    },
                  ),
                  borderRadius: AppRadius.sm,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '$quantity',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _QtyBtn(
                  icon: Icons.add,
                  onTap: () => context.read<CartCubit>().updateQuantity(
                    product.id,
                    quantity + 1,
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onLongPress: () => showQuantitySelectorSheet(
            context,
            productName: product.drugName,
            initialQuantity: 10,
            maxStock: product.countInStock,
            onQuantitySelected: (newQty) {
              context.read<CartCubit>().addItemWithQuantity(product, newQty);
            },
          ),
          child: IconButton.filledTonal(
            onPressed: onAddToCart,
            icon: Icon(Icons.add_shopping_cart_rounded, size: 18.w),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
              padding: EdgeInsets.all(8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Icon(icon, size: 14.w, color: AppColors.primary),
      ),
    );
  }
}
