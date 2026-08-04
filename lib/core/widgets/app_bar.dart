import 'brand_lockup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config.dart';
import 'cart_badge_icon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HealMealAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HealMealAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.showSearch = false,
    this.showCart = false,
    this.transparent = false,
    this.actions,
    this.onBack,
    this.bottom,
  });

  final String? title;
  final bool showBack;
  final bool showSearch;
  final bool showCart;
  final bool transparent;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final fg = transparent
        ? AppColors.white
        : Theme.of(context).colorScheme.onSurface;
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : null,
      bottom: bottom,
      leadingWidth: showBack ? null : 60,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg),
              onPressed:
                  onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
            )
          : Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Center(
                child: Image.asset(
                  AppAssets.logo,
                  height: 34.h,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.local_hospital_rounded),
                ),
              ),
            ),
      title: title == null
          ? BrandLockup(onDark: transparent)
          : Text(title!, style: AppTextStyles.h2.copyWith(color: fg)),
      centerTitle: showBack,
      actions: [
        if (showSearch)
          IconButton(
            onPressed: () => context.go('/search'),
            icon: Icon(Icons.search_rounded, color: fg),
          ),
        if (showCart)
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: CartBadgeIcon(color: fg),
          ),
        ...?actions,
      ],
    );
  }
}
