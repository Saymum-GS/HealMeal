import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/localization.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../cart/cart_cubit.dart';
import 'orders_cubit.dart';
import '../checkout/checkout_screens.dart';
import '../account/screens/lab_order_list.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedType = 'medicines';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: context.strings.myOrders, showBack: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'medicines',
                    label: Text('Medicine Orders'),
                    icon: Icon(Icons.medication_outlined),
                  ),
                  ButtonSegment(
                    value: 'labs',
                    label: Text('Lab Bookings'),
                    icon: Icon(Icons.science_outlined),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedType = set.first;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: _selectedType == 'medicines'
                ? const _MedicineOrdersView()
                : const _LabOrdersView(),
          ),
        ],
      ),
    );
  }
}

class _MedicineOrdersView extends StatelessWidget {
  const _MedicineOrdersView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            tabs: <Tab>[
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                final orders = state.orders;
                return TabBarView(
                  children: <Widget>[
                    _OrderList(orders: orders),
                    _OrderList(
                      orders: orders
                          .where(
                            (o) =>
                                o.status != OrderStatus.delivered &&
                                o.status != OrderStatus.cancelled,
                          )
                          .toList(),
                    ),
                    _OrderList(
                      orders: orders
                          .where((o) => o.status == OrderStatus.delivered)
                          .toList(),
                    ),
                    _OrderList(
                      orders: orders
                          .where((o) => o.status == OrderStatus.cancelled)
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LabOrdersView extends StatelessWidget {
  const _LabOrdersView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: <Tab>[
              Tab(text: 'Upcoming'),
              Tab(text: 'Processing'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                final labOrders = state.labBookings;
                return TabBarView(
                  children: <Widget>[
                    LabOrderList(
                      items: labOrders
                          .where(
                            (item) => item.status == LabBookingStatus.upcoming,
                          )
                          .toList(),
                    ),
                    LabOrderList(
                      items: labOrders
                          .where(
                            (item) =>
                                item.status == LabBookingStatus.processing,
                          )
                          .toList(),
                    ),
                    LabOrderList(
                      items: labOrders
                          .where(
                            (item) => item.status == LabBookingStatus.completed,
                          )
                          .toList(),
                    ),
                    LabOrderList(
                      items: labOrders
                          .where(
                            (item) => item.status == LabBookingStatus.cancelled,
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});
  final List<AppOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyStateWidget(type: EmptyStateType.orders);
    }
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: orders.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  context.push('/orders/${order.id.replaceAll('#', '')}'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.colorSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.formattedCode,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        StatusBadge(status: order.status.label),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14.w,
                          color: context.colorTextSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          AppFormatters.longDate(order.placedAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      order.medicineNamesSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          '${order.items.length} items',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.colorTextSecondary,
                          ),
                        ),
                        Spacer(),
                        Text(
                          AppFormatters.taka(order.total),
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: SizedBox(height: 1),
                    ),
                    Row(
                      children: [
                        if (order.status == OrderStatus.placed)
                          TextButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => ConfirmDialog(
                                  title: 'Cancel Order',
                                  body:
                                      'Are you sure you want to cancel this order?',
                                  confirmLabel: 'Cancel Order',
                                  isDangerous: true,
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                try {
                                  await context.read<OrdersCubit>().cancelOrder(order.id);
                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      'Order cancelled successfully',
                                      type: ToastType.success,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      'Failed to cancel order: $e',
                                      type: ToastType.error,
                                    );
                                  }
                                }
                              }
                            },
                            icon: Icon(Icons.cancel_outlined, size: 16.w),
                            label: Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          )
                        else if (order.status == OrderStatus.cancelled)
                          TextButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => ConfirmDialog(
                                  title: 'Remove Order',
                                  body:
                                      'Are you sure you want to remove this order from your history?',
                                  confirmLabel: 'Remove',
                                  isDangerous: true,
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                try {
                                  await context.read<OrdersCubit>().hideOrder(order.id);
                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      'Order removed from history',
                                      type: ToastType.success,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      'Failed to remove order: $e',
                                      type: ToastType.error,
                                    );
                                  }
                                }
                              }
                            },
                            icon: Icon(Icons.delete_outline, size: 16.w),
                            label: Text('Remove'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.muted,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              for (var item in order.items) {
                                context.read<CartCubit>().addItem(item.product);
                              }
                              AppToast.show(
                                context,
                                'Items added to cart',
                                type: ToastType.success,
                              );
                              context.push('/cart');
                            },
                            icon: Icon(Icons.replay_rounded, size: 16.w),
                            label: Text('Reorder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        Spacer(),
                        Row(
                          children: [
                            Text(
                              'View Details',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12.w,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 140.w,
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF38ef7d), Color(0xFF11998e)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF38ef7d),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 60.w,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Order Placed\nSuccessfully!',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Thank you for your order. We are processing it and will deliver it to you soon.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48.h),
                    HealMealButton(
                      label: 'Track Order',
                      size: ButtonSize.large,
                      onPressed: () => context.go('/orders'),
                    ),
                    SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 32.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Continue Browsing',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32.h),
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
                      child:
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 80.w,
                          ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8,
                    ),
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
                  SizedBox(height: 64.h),

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
                          value:
                              order?.paymentMethod.label ?? 'Cash on Delivery',
                        ),
                        SizedBox(height: AppSpacing.md),
                        if (order != null) _OrderItemsCard(order: order),
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
                    color: context.colorTextSecondary,
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
      appBar: HealMealAppBar(title: order.formattedCode, showBack: true),
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
          SizedBox(height: 16.h),
          _OrderActions(order: order),
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
    // Determine current progress index
    final List<OrderStatus> flow = [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    int currentIndex = 0;
    if (order.status == OrderStatus.confirmed) currentIndex = 1;
    if (order.status == OrderStatus.dispatched) currentIndex = 1;
    if (order.status == OrderStatus.outForDelivery) currentIndex = 2;
    if (order.status == OrderStatus.delivered) currentIndex = 3;

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
          ...List.generate(flow.length, (index) {
            final stepStatus = flow[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == flow.length - 1;

            // Find actual time if available in timeline
            DateTime? stepTime;
            for (var t in order.timeline) {
              if (t.status.toLowerCase().contains(
                stepStatus.label.toLowerCase(),
              )) {
                stepTime = t.time;
              }
            }
            if (index == 0) stepTime = order.placedAt;

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
                        color: isCompleted
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.success
                              : context.colorBorder,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(Icons.check, size: 14.w, color: Colors.white)
                          : (isCurrent && order.status != OrderStatus.delivered
                                ? Icon(
                                    Icons.sync_rounded,
                                    size: 14.w,
                                    color: AppColors.primary,
                                  )
                                : null),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32.h,
                        color: isCompleted && !isCurrent
                            ? AppColors.success
                            : context.colorBorder,
                      ),
                  ],
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepStatus.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isCompleted
                              ? null
                              : context.colorTextSecondary,
                          fontWeight: isCurrent ? FontWeight.bold : null,
                        ),
                      ),
                      if (stepTime != null)
                        Text(
                          AppFormatters.compactDateTime(stepTime),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.colorTextSecondary,
                          ),
                        ),
                      if (isCurrent && stepStatus == OrderStatus.outForDelivery)
                        Text(
                          'Estimated Delivery: Today',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
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
                productId: item.product.id,
                hasImage: item.product.hasImage,
                label: item.product.drugName,
                width: 48.w,
                height: 48.h,
              ),
              title: Text(item.product.drugName),
              subtitle: Text(
                '${item.quantity} x ${item.product.effectivePrice}',
              ),
              trailing: Text(AppFormatters.taka(item.subtotal)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order});
  final AppOrder order;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (order.status == OrderStatus.placed ||
            order.status == OrderStatus.confirmed)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: HealMealButton(
              label: 'Cancel Order',
              type: ButtonType.outlined,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => ConfirmDialog(
                    title: 'Cancel Order',
                    body: 'Are you sure you want to cancel this order?',
                    confirmLabel: 'Cancel Order',
                    isDangerous: true,
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<OrdersCubit>().cancelOrder(order.id);
                  AppToast.show(
                    context,
                    'Order cancelled successfully',
                    type: ToastType.success,
                  );
                  context.pop(); // Go back to orders list
                }
              },
            ),
          )
        else if (order.status == OrderStatus.cancelled)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: HealMealButton(
              label: 'Remove Order',
              type: ButtonType.outlined,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => ConfirmDialog(
                    title: 'Remove Order',
                    body:
                        'Are you sure you want to remove this order from your history?',
                    confirmLabel: 'Remove',
                    isDangerous: true,
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<OrdersCubit>().hideOrder(order.id);
                  AppToast.show(
                    context,
                    'Order removed from history',
                    type: ToastType.success,
                  );
                  context.pop(); // Go back to orders list
                }
              },
            ),
          ),
        HealMealButton(
          label: 'Reorder All Items',
          onPressed: () {
            for (var item in order.items) {
              context.read<CartCubit>().addItem(item.product);
            }
            AppToast.show(
              context,
              'Items added to cart',
              type: ToastType.success,
            );
            context.push('/cart');
          },
        ),
      ],
    );
  }
}
