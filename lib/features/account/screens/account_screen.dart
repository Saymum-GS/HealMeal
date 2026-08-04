import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../../../core/widgets.dart';
import '../../../core/theme.dart';
import '../../../core/localization.dart';
import '../account_widgets.dart';
import '../../auth/auth_cubit.dart';

import 'account_header.dart';
import 'account_menu_widgets.dart';
import 'lang_toggle.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const _UnauthenticatedAccountView();
    }

    return _AuthenticatedAccountView(authState: authState);
  }
}

class _UnauthenticatedAccountView extends StatelessWidget {
  const _UnauthenticatedAccountView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Compact header with generic avatar
              Container(
                height: 160.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 80.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_circle_rounded,
                          size: 64.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Welcome to HealMeal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    Text(
                      'Sign in to access your orders, wishlist, prescriptions, lab reports, and cashback wallet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colorTextSecondary),
                    ),
                    SizedBox(height: 24.h),
                    HealMealButton(
                      label: 'Login',
                      size: ButtonSize.large,
                      onPressed: () => context.push('/login'),
                    ),
                    SizedBox(height: 12.h),
                    HealMealButton(
                      label: 'Create Account',
                      type: ButtonType.outlined,
                      size: ButtonSize.large,
                      onPressed: () => context.push('/register'),
                    ),
                    SizedBox(height: 32.h),
                    // Show publicly accessible items only
                    AccountMenuSection(
                      title: 'Support & Info',
                      children: [
                        AccountMenuTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & FAQ',
                          route: '/faq',
                          onTap: () => context.push('/faq'),
                        ),
                        AccountMenuTile(
                          icon: Icons.phone_outlined,
                          label: 'Contact Us',
                          route: '/contact',
                          onTap: () => context.push('/contact'),
                        ),
                        AccountMenuTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About HealMeal',
                          route: '/about',
                          onTap: () => context.push('/about'),
                        ),
                        AccountMenuTile(
                          icon: Icons.chat_outlined,
                          label: 'WhatsApp Support',
                          route: 'https://wa.me/8801325188042',
                          external: true,
                        ),
                      ],
                    ),
                    AccountMenuSection(
                      title: 'Legal',
                      children: [
                        AccountMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          route: '/privacy',
                          onTap: () => context.push('/privacy'),
                        ),
                        AccountMenuTile(
                          icon: Icons.description_outlined,
                          label: 'Terms & Conditions',
                          route: '/terms',
                          onTap: () => context.push('/terms'),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
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

class _AuthenticatedAccountView extends StatelessWidget {
  final AuthAuthenticated authState;

  const _AuthenticatedAccountView({required this.authState});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final strings = context.strings;

    String name = authState.name ?? 'No Name';
    String email = authState.email ?? 'No Email';
    String? photoUrl = authState.photoUrl;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: AccountHeader(
            name: name,
            email: email,
            photoUrl: photoUrl,
            onEdit: () => context.push('/account/edit'),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CardSection(
              title: 'App Preferences',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isDark ? strings.darkMode : strings.lightMode,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: isDark,
                        onChanged: (_) =>
                            context.read<ThemeCubit>().toggleTheme(),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Text(
                        '${strings.language}:',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Spacer(),
                      LangToggle(
                        isBangla: context.isBangla,
                        onEnglish: () =>
                            context.read<LocaleCubit>().setEnglish(),
                        onBangla: () => context.read<LocaleCubit>().setBangla(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Column(
              children: <Widget>[
                GridView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 110,
                  ),
                  children: [
                    GridMenuCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'My Orders',
                      onTap: () => context.push('/orders'),
                    ),
                    GridMenuCard(
                      icon: Icons.science_outlined,
                      label: 'Lab Tests',
                      onTap: () => context.push('/labs'),
                    ),
                    GridMenuCard(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Wishlist',
                      onTap: () => context.push('/account/wishlist'),
                    ),
                    GridMenuCard(
                      icon: Icons.upload_file_outlined,
                      label: 'Prescriptions',
                      onTap: () => context.push('/prescriptions/upload'),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxl),
                CollapsibleMenuSection(
                  title: context.tr('Medicines & Reviews', 'শপিং ও রিভিউ'),
                  icon: Icons.shopping_bag_outlined,
                  children: <Widget>[
                    AccountMenuTile(
                      icon: Icons.star_outline_rounded,
                      label: 'Medicine Review',
                      route: '/account/product-reviews',
                      onTap: () => context.push('/account/product-reviews'),
                    ),
                    AccountMenuTile(
                      icon: Icons.notifications_active_outlined,
                      label: 'Notified Medicines',
                      route: '/account/notified-products',
                      onTap: () => context.push('/account/notified-products'),
                    ),
                    AccountMenuTile(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Suggest a Medicine',
                      route: '/account/suggest-product',
                      onTap: () => context.push('/account/suggest-product'),
                    ),
                    AccountMenuTile(
                      icon: Icons.local_offer_outlined,
                      label: 'Special Offers',
                      route: '/products?featured=true',
                      onTap: () => context.push('/products?featured=true'),
                    ),
                  ],
                ),

                CollapsibleMenuSection(
                  title: context.tr('Support & Legal', 'সহায়তা ও আইনি'),
                  icon: Icons.help_outline_rounded,
                  children: <Widget>[
                    AccountMenuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & FAQ',
                      route: '/faq',
                      onTap: () => context.push('/faq'),
                    ),
                    AccountMenuTile(
                      icon: Icons.assignment_return_outlined,
                      label: 'Return Policy',
                      route: '/return-policy',
                      onTap: () => context.push('/return-policy'),
                    ),
                    AccountMenuTile(
                      icon: Icons.phone_outlined,
                      label: 'Contact Us',
                      route: '/contact',
                      onTap: () => context.push('/contact'),
                    ),
                    AccountMenuTile(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp Support',
                      route:
                          'https://wa.me/8801325188042?text=Hello%20HealMeal%20Support',
                      external: true,
                    ),
                    AccountMenuTile(
                      icon: Icons.article_outlined,
                      label: 'Health Tips',
                      route: '/blog',
                      onTap: () => context.push('/blog'),
                    ),
                    AccountMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      route: '/privacy',
                      onTap: () => context.push('/privacy'),
                    ),
                    AccountMenuTile(
                      icon: Icons.description_outlined,
                      label: 'Terms & Conditions',
                      route: '/terms',
                      onTap: () => context.push('/terms'),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      final bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) => ConfirmDialog(
                          title: 'Logout',
                          body: 'Are you sure you want to logout?',
                          confirmLabel: 'Logout',
                          isDangerous: true,
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<AuthCubit>().logout();
                        if (context.mounted) {
                          context.go('/home');
                        }
                      }
                    },
                    child: Text(
                      strings.logout,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
