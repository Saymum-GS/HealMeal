import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/widgets.dart';
import '../../core/models.dart';
import '../cart/cart_cubit.dart';

import '../auth/auth_cubit.dart';
import '../orders/orders_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// -- Home Screen Sections ---------------------------------------------------

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: context.colorSurface.withOpacity(0.85),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              AppAssets.logo,
              height: 24.h,
              width: 24.w,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.local_hospital_rounded, color: AppColors.primary),
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HealMeal',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Trusted Online Pharmacy',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.subtle.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              size: 22.w,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.push('/account/notifications'),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: AppColors.subtle.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: CartBadgeIcon(size: 22.w),
        ),
      ],
    );
  }
}

class SearchHero extends StatelessWidget {
  const SearchHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white,
              borderRadius: AppRadius.pill,
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.15),
              child: InkWell(
                onTap: () => context.go('/search'),
                borderRadius: AppRadius.pill,
                child: Container(
                  height: 54.h,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 24.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Search medicine, generic, brand...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.muted,
                            fontSize: 15.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryActionGrid extends StatelessWidget {
  const PrimaryActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionItem(
              label: 'Medicines',
              icon: Icons.medication_liquid_rounded,
              gradient: LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => context.push('/products'),
            ),
            SizedBox(width: 12.w),
            _ActionItem(
              label: 'Upload Rx',
              icon: Icons.document_scanner_rounded,
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                final isGuest =
                    context.read<AuthCubit>().state is AuthUnauthenticated;
                if (isGuest) {
                  showGuestAccountSheet(
                    context,
                    customMessage:
                        'Sign in to upload prescriptions and we will help match your medicines.',
                  );
                } else {
                  context.push('/prescriptions/upload');
                }
              },
            ),
            SizedBox(width: 12.w),
            _ActionItem(
              label: 'Lab Tests',
              icon: Icons.biotech_rounded,
              gradient: LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => context.push('/labs'),
            ),
            SizedBox(width: 12.w),
            _ActionItem(
              label: 'Reorder',
              icon: Icons.restart_alt_rounded,
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                final isGuest =
                    context.read<AuthCubit>().state is AuthUnauthenticated;
                if (isGuest) {
                  showGuestAccountSheet(
                    context,
                    customMessage:
                        'Sign in to view your order history and easily reorder medicines.',
                  );
                } else {
                  context.push('/orders');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 60.h,
              width: 60.w,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28.w),
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PrescriptionHeroStrip extends StatelessWidget {
  const PrescriptionHeroStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF042F2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF042F2E).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AI-ASSISTED',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 9.sp,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Order via\nPrescription',
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    height: 1.1,
                    fontSize: 22.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    final isGuest =
                        context.read<AuthCubit>().state is AuthUnauthenticated;
                    if (isGuest) {
                      showGuestAccountSheet(
                        context,
                        customMessage: 'Sign in to upload your prescription.',
                      );
                    } else {
                      context.push('/prescriptions/upload');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF0F766E),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_rounded, size: 18.w),
                      SizedBox(width: 8.w),
                      Text(
                        'Upload Rx',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 48.w,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickReorderWidget extends StatelessWidget {
  const QuickReorderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthUnauthenticated) {
          return SizedBox.shrink();
        }

        return BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, orderState) {
            if (orderState.orders.isEmpty) return SizedBox.shrink();

            final lastOrder = orderState.orders.first;
            return MedicineShelf(
              products: lastOrder.items.map((i) => i.product).toList(),
              title: 'Reorder medicines',
              subtitle: 'From your last order',
              icon: Icons.history_rounded,
            );
          },
        );
      },
    );
  }
}

class LabTestHomeModule extends StatelessWidget {
  const LabTestHomeModule({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/labs'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colorBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 60.h,
              width: 60.w,
              decoration: BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.biotech_rounded,
                color: Color(0xFF3B82F6),
                size: 32.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lab Tests at Home',
                    style: AppTextStyles.h3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Certified sample collection with digital reports.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.muted,
              size: 16.w,
            ),
          ],
        ),
      ),
    );
  }
}

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      margin: EdgeInsets.only(top: 16.h, bottom: 16.h),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.03)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TrustItem(icon: Icons.verified_user_rounded, label: '100% Genuine'),
          _TrustItem(icon: Icons.payments_rounded, label: 'COD Available'),
          _TrustItem(
            icon: Icons.local_shipping_rounded,
            label: 'Fast Delivery',
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 22.w),
        ),
        SizedBox(height: 12.h),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class MedicineShelf extends StatelessWidget {
  const MedicineShelf({
    super.key,
    required this.products,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onSeeAll,
  });

  final List<Product> products;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (accentColor ?? AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor ?? AppColors.primary,
                    size: 18.w,
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(fontSize: 18.sp),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.primary.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'See All',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 210.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 160.w,
                child: ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                  onAddToCart: () {
                    context.read<CartCubit>().addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.drugName} added to cart'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
