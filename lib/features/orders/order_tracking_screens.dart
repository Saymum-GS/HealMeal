import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:healmeal_app/core/config.dart';
import 'package:healmeal_app/core/models.dart';
import 'package:healmeal_app/core/localization.dart';
import 'package:healmeal_app/core/utils.dart';
import 'package:healmeal_app/core/widgets.dart';
import '../checkout/checkout_screens.dart';
import 'orders_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersCubit>().lastPlacedAppOrder;
    return Scaffold(
      body: Stack(
        children: [
          // Celebratory Gradient Background
          Container(
            height: MediaQuery.of(context).size.height * .55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
          ),

          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: 50.h,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.03),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Spacer(flex: 1),
                // Animated-like Success Icon
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 80.w,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.strings.orderPlaced,
                  style: AppTextStyles.displayHero.copyWith(
                    color: AppColors.white,
                    fontSize: 32.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order?.id ?? 'Processing...',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
                Spacer(flex: 2),

                // Content Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ConfirmationRow(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Estimated Delivery',
                        value: 'Fast track delivery within 24 hours',
                      ),
                      SizedBox(height: AppSpacing.md),
                      _ConfirmationRow(
                        icon: Icons.account_balance_wallet_rounded,
                        title: context.strings.paymentMethod,
                        value: order?.paymentMethod.label ?? 'Cash on Delivery',
                      ),
                      SizedBox(height: AppSpacing.md),
                      if (order?.cashbackUsed != null &&
                          order!.cashbackUsed > 0)
                        InfoBanner(
                          title: 'Cashback Applied',
                          body:
                              'You used ৳${order.cashbackUsed.toStringAsFixed(0)} cashback for this order.',
                          type: InfoBannerType.success,
                        ),
                      SizedBox(height: AppSpacing.xl),
                      HealMealButton(
                        label: context.strings.trackOrder,
                        size: ButtonSize.large,
                        onPressed: () => context.go(
                          order == null
                              ? '/orders'
                              : '/orders/${order.id.replaceAll('#', '')}',
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      HealMealButton(
                        label: context.strings.continueShopping,
                        type: ButtonType.outlined,
                        size: ButtonSize.large,
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.md,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersCubit>().findById(id);
    if (order == null) {
      return Scaffold(body: Center(child: Text('Order not found')));
    }

    return Scaffold(
      appBar: HealMealAppBar(title: order.id, showBack: true),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _TrackingHeader(order: order),
          SizedBox(height: 16.h),
          _TimelineCard(order: order),
          SizedBox(height: 16.h),
          _OrderItemsCard(order: order),
          SizedBox(height: 16.h),
          PriceSummaryCard(
            subtotal: order.subtotal,
            discount: order.discountAmount,
            deliveryCharge: order.deliveryCharge,
            tax: order.taxAmount,
            cashbackUsed: order.cashbackUsed,
            total: order.total,
          ),
        ],
      ),
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({required this.order});
  final AppOrder order;

  @override
  Widget build(BuildContext context) {
    double progress = 0.2;
    if (order.status == OrderStatus.confirmed) progress = 0.4;
    if (order.status == OrderStatus.dispatched) progress = 0.6;
    if (order.status == OrderStatus.outForDelivery) progress = 0.8;
    if (order.status == OrderStatus.delivered) progress = 1.0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark.withOpacity(0.8)],
        ),
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Order',
                      style: AppTextStyles.h1.copyWith(color: AppColors.white),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      order.id,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: order.status.label),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Stack(
            children: [
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: Duration(seconds: 1),
                height: 8.h,
                width: (MediaQuery.of(context).size.width - 64) * progress,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.white54, blurRadius: 4)],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Placed',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
              Text(
                'Dispatched',
                style: AppTextStyles.labelSmall.copyWith(
                  color: progress >= 0.6 ? AppColors.white : Colors.white38,
                ),
              ),
              Text(
                'Delivered',
                style: AppTextStyles.labelSmall.copyWith(
                  color: progress == 1.0 ? AppColors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});
  final AppOrder order;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Updates', style: AppTextStyles.h2),
          SizedBox(height: AppSpacing.lg),
          ...List.generate(order.timeline.length, (index) {
            final step = order.timeline[index];
            final isLast = index == order.timeline.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.completed
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: step.completed
                              ? AppColors.success
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: step.completed
                          ? Icon(Icons.check, size: 14.w, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32.h,
                        color: step.completed
                            ? AppColors.success
                            : AppColors.border,
                      ),
                  ],
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.status,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: step.completed ? null : AppColors.secondary,
                        ),
                      ),
                      Text(
                        AppFormatters.compactDateTime(step.time),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});
  final AppOrder order;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: AppTextStyles.h2),
          SizedBox(height: 12.h),
          ...order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: HealMealImage(
                imageUrl: item.product.imageUrl,
                label: item.product.drugName,
                width: 48.w,
                height: 48.h,
              ),
              title: Text(item.product.drugName),
              subtitle: Text('${item.quantity} x ${item.product.salePrice}'),
              trailing: Text(AppFormatters.taka(item.subtotal)),
            ),
          ),
        ],
      ),
    );
  }
}
