import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'HealMeal Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'System Control Center',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            route: '/admin',
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              context.go('/admin');
            },
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 8, bottom: 4),
            child: Text(
              'E-COMMERCE',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.colorTextMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.medication_rounded,
            label: 'Medicines',
            route: '/admin/products',
            onTap: () => context.push('/admin/products'),
          ),
          _DrawerItem(
            icon: Icons.inventory_2_rounded,
            label: 'Inventory / Stock',
            route: '/admin/inventory',
            onTap: () => context.push('/admin/inventory'),
          ),
          _DrawerItem(
            icon: Icons.category_rounded,
            label: 'Categories',
            route: '/admin/categories',
            onTap: () => context.push('/admin/categories'),
          ),

          _DrawerItem(
            icon: Icons.receipt_long_rounded,
            label: 'Orders',
            route: '/admin/orders',
            onTap: () => context.push('/admin/orders'),
          ),
          _DrawerItem(
            icon: Icons.assignment_rounded,
            label: 'Prescriptions',
            route: '/admin/prescriptions',
            onTap: () => context.push('/admin/prescriptions'),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 8, bottom: 4),
            child: Text(
              'HEALTHCARE SERVICES',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.colorTextMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.biotech_rounded,
            label: 'Lab Tests Catalog',
            route: '/admin/lab-tests',
            onTap: () => context.push('/admin/lab-tests'),
          ),
          _DrawerItem(
            icon: Icons.science_rounded,
            label: 'Lab Bookings',
            route: '/admin/lab-bookings',
            onTap: () => context.push('/admin/lab-bookings'),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 8, bottom: 4),
            child: Text(
              'MARKETING',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.colorTextMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _DrawerItem(
            icon: Icons.card_giftcard_rounded,
            label: 'Coupons',
            route: '/admin/coupons',
            onTap: () => context.push('/admin/coupons'),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 8, bottom: 4),
            child: Text(
              'ENGAGEMENT & USERS',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.colorTextMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.people_rounded,
            label: 'Users & Roles',
            route: '/admin/users',
            onTap: () => context.push('/admin/users'),
          ),
          _DrawerItem(
            icon: Icons.rate_review_rounded,
            label: 'Reviews',
            route: '/admin/reviews',
            onTap: () => context.push('/admin/reviews'),
          ),
          _DrawerItem(
            icon: Icons.support_agent_rounded,
            label: 'Support Tickets',
            route: '/admin/support',
            onTap: () => context.push('/admin/support'),
          ),
          _DrawerItem(
            icon: Icons.chat_rounded,
            label: 'Support Chat',
            route: '/admin/chat',
            onTap: () => context.push('/admin/chat'),
          ),
          _DrawerItem(
            icon: Icons.lightbulb_rounded,
            label: 'Suggestions',
            route: '/admin/suggestions',
            onTap: () => context.push('/admin/suggestions'),
          ),
          _DrawerItem(
            icon: Icons.article_rounded,
            label: 'Health Tips / Articles',
            route: '/admin/articles',
            onTap: () => context.push('/admin/articles'),
          ),
          _DrawerItem(
            icon: Icons.question_answer_rounded,
            label: 'FAQs',
            route: '/admin/faqs',
            onTap: () => context.push('/admin/faqs'),
          ),
          _DrawerItem(
            icon: Icons.settings_rounded,
            label: 'Platform Settings',
            route: '/admin/settings',
            onTap: () => context.push('/admin/settings'),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isActive =
        currentLocation == route || currentLocation.startsWith('$route/');

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : context.colorTextSecondary,
      ),
      title: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: isActive ? AppColors.primary : null,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      onTap: onTap,
    );
  }
}
