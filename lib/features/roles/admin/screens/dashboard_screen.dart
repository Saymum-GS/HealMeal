import '../../../auth/auth_cubit.dart';
import 'admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/utils.dart';
import '../../../../core/widgets.dart';
import '../../../../core/repositories.dart';
import '../../../../core/services.dart';
import '../admin_cubit.dart';
import 'components.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderCubit>().fetchOrders();
      context.read<AdminUserCubit>().loadUsers();

      context.read<AdminSuggestionCubit>().startWatchingSuggestions();
      context.read<AdminLabBookingCubit>().startWatchingLabBookings();
      context.read<AdminInventoryCubit>().loadInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = context.watch<AdminOrderCubit>().state;
    final userState = context.watch<AdminUserCubit>().state;

    final labState = context.watch<AdminLabBookingCubit>().state;
    final inventoryState = context.watch<AdminInventoryCubit>().state;

    if (orderState.isLoading ||
        userState.isLoading ||
        labState.isLoading ||
        inventoryState is AdminInventoryLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        final bodyContent = ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.xl : AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          children: [
            Text('Overview', style: AppTextStyles.h1),
            SizedBox(height: AppSpacing.md),
            _AnalyticsOverview(
              orders: orderState.allOrders,
              usersCount: userState.allUsers.length,
              labBookingsCount: labState.labBookings.length,
            ),
            SizedBox(height: AppSpacing.xl),

            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _RevenueTrend(orders: orderState.allOrders),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 5,
                    child: _RecentOrdersList(orders: orderState.allOrders),
                  ),
                ],
              )
            else ...[
              _RevenueTrend(orders: orderState.allOrders),
              SizedBox(height: AppSpacing.xl),
              _RecentOrdersList(orders: orderState.allOrders),
            ],
            SizedBox(height: AppSpacing.xl),
            _SupportChatSummary(),
            SizedBox(height: AppSpacing.xl),
            Text('Quick Actions', style: AppTextStyles.h2),
            SizedBox(height: AppSpacing.sm),
            _QuickActionsGrid(),
            SizedBox(height: AppSpacing.xl),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                SizedBox(
                  width: 260.w,
                  child: AdminDrawer(), // Used as a persistent sidebar
                ),
                VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text('Admin Dashboard'),
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      actions: [
                        IconButton(
                          onPressed: () => context.read<AuthCubit>().logout(),
                          icon: Icon(Icons.logout_rounded),
                          tooltip: 'Logout',
                        ),
                        SizedBox(width: AppSpacing.md),
                      ],
                    ),
                    body: bodyContent,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Admin Dashboard'),
            actions: <Widget>[
              IconButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: Icon(Icons.logout_rounded),
                tooltip: 'Logout',
              ),
            ],
          ),
          drawer: AdminDrawer(),
          body: bodyContent,
        );
      },
    );
  }
}

class _SupportChatSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatConversation>>(
      stream: getIt<ChatRepository>().allConversationsStream(),
      builder: (context, snapshot) {
        final convs = snapshot.data ?? [];
        final unreadCount = convs.fold<int>(
          0,
          (sum, c) => sum + c.unreadByAdmin,
        );
        final hasUnread = unreadCount > 0;

        return InkWell(
          onTap: () => context.push('/admin/chat'),
          borderRadius: AppRadius.lg,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasUnread
                    ? [
                        AppColors.accentOrange.withOpacity(0.1),
                        AppColors.accentOrange.withOpacity(0.05),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
              ),
              borderRadius: AppRadius.lg,
              border: Border.all(
                color: hasUnread
                    ? AppColors.accentOrange
                    : AppColors.primary.withOpacity(0.3),
                width: hasUnread ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: hasUnread
                        ? AppColors.accentOrange
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 28.w,
                  ),
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Support Chat',
                        style: AppTextStyles.h3.copyWith(
                          color: hasUnread ? AppColors.accentOrange : null,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        hasUnread
                            ? '$unreadCount new message(s) from users'
                            : '${convs.length} active conversation(s)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.colorTextMuted,
                  size: 20.w,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnalyticsOverview extends StatelessWidget {
  const _AnalyticsOverview({
    required this.orders,
    required this.usersCount,
    required this.labBookingsCount,
  });
  final List<AppOrder> orders;
  final int usersCount;
  final int labBookingsCount;

  @override
  Widget build(BuildContext context) {
    final pendingOrders = orders
        .where(
          (o) =>
              o.status == OrderStatus.placed ||
              o.status == OrderStatus.confirmed,
        )
        .length;
    final metrics = [
      (
        title: 'Total Revenue',
        value: AppFormatters.taka(orders.fold(0.0, (sum, o) => sum + o.total)),
        color: AppColors.primary,
      ),
      (
        title: 'Total Orders',
        value: '${orders.length}',
        color: AppColors.success,
      ),
      (
        title: 'Pending Orders',
        value: '$pendingOrders',
        color: AppColors.error,
      ),
      (
        title: 'Lab Bookings',
        value: '$labBookingsCount',
        color: AppColors.warning,
      ),

      (title: 'Active Users', value: '$usersCount', color: AppColors.primary),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppLayout.adminStatColumns(
          AppLayout.screenWidth(context),
        ),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 120,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [m.color.withOpacity(0.1), m.color.withOpacity(0.05)],
            ),
            borderRadius: AppRadius.lg,
            border: Border.all(color: m.color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: m.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(m.value, style: AppTextStyles.h2.copyWith(color: m.color)),
            ],
          ),
        );
      },
    );
  }
}

class _RevenueTrend extends StatelessWidget {
  const _RevenueTrend({required this.orders});
  final List<AppOrder> orders;

  List<double> _calculateDailyRevenue() {
    final now = DateTime.now();
    final List<double> revenues = List.filled(7, 0.0);
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final order in orders) {
      if (order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.failed) {
        continue;
      }
      final diff = todayStart
          .difference(
            DateTime(
              order.placedAt.year,
              order.placedAt.month,
              order.placedAt.day,
            ),
          )
          .inDays;
      if (diff >= 0 && diff < 7) {
        revenues[6 - diff] += order.total;
      }
    }
    return revenues;
  }

  List<String> _getLast7DaysLabels() {
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      if (i == 0) {
        labels.add('Today');
      } else {
        labels.add(
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
        );
      }
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final revenues = _calculateDailyRevenue();
    final labels = _getLast7DaysLabels();
    final maxRevenue = revenues.fold(0.0, (max, val) => val > max ? val : max);
    final scaleFactor = maxRevenue > 0 ? 100.0 / maxRevenue : 0.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenue Trend (7 Days)', style: AppTextStyles.h3),
              Icon(Icons.show_chart_rounded, color: AppColors.primary),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 150.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final revenue = revenues[index];
                final height = revenue == 0
                    ? 4.0
                    : 20.0 + (revenue * scaleFactor);
                return Expanded(
                  child: Tooltip(
                    message: AppFormatters.taka(revenue),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((day) => Text(day, style: AppTextStyles.bodySmall))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  const _RecentOrdersList({required this.orders});
  final List<AppOrder> orders;

  @override
  Widget build(BuildContext context) {
    // Fetch orders if not already loaded (handled by screen builder if needed)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Orders', style: AppTextStyles.h2),
            HealMealButton(
              type: ButtonType.text,
              onPressed: () => context.push('/admin/orders'),
              label: 'View All',
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        ...orders.take(5).map((order) {
          return RoleCard(
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.md,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.id, style: AppTextStyles.labelLarge),
                      Text(
                        AppFormatters.taka(order.total),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status.name),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'Add Medicine',
        icon: Icons.add_box_rounded,
        route: '/admin/products/add',
      ),

      (
        label: 'Coupons',
        icon: Icons.card_giftcard_rounded,
        route: '/admin/coupons',
      ),

      (
        label: 'Orders',
        icon: Icons.receipt_long_rounded,
        route: '/admin/orders',
      ),
      (
        label: 'Prescriptions',
        icon: Icons.assignment_rounded,
        route: '/admin/prescriptions',
      ),
      (
        label: 'Lab Tests',
        icon: Icons.biotech_rounded,
        route: '/admin/lab-tests',
      ),
      (
        label: 'Categories',
        icon: Icons.category_rounded,
        route: '/admin/categories',
      ),
      (label: 'Users', icon: Icons.people_rounded, route: '/admin/users'),
      (
        label: 'FAQs',
        icon: Icons.question_answer_rounded,
        route: '/admin/faqs',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return InkWell(
          onTap: () => context.push(a.route),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 54.w,
                width: 54.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, color: AppColors.primary, size: 24.w),
              ),
              SizedBox(height: 8.h),
              Text(
                a.label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
