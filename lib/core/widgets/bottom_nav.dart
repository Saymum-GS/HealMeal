import 'dart:ui';

import 'package:flutter/material.dart';

import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HealMealBottomNav extends StatelessWidget {
  const HealMealBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.isGuest = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Home', icon: Icons.home_rounded, activeIcon: Icons.home_rounded),
      (
        label: 'Shop',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
      ),
      (
        label: 'Lab Test',
        icon: Icons.science_outlined,
        activeIcon: Icons.science_rounded,
      ),
      (
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
      ),
      (
        label: 'Account',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.white;
    final selectedColor = isDark ? AppColors.accentTeal : AppColors.primary;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: navBg.withOpacity(0.92),
            border: Border(
              top: BorderSide(
                color: (isDark ? AppColors.darkBorder : context.colorBorder)
                    .withOpacity(0.5),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = currentIndex == index;
                  Widget iconWidget;
                  if (index == 3 && cartCount > 0) {
                    // Actually, cart isn't on bottom nav anymore. So cartCount badge shouldn't be here. But wait, orders doesn't use cartCount. So I'll just remove the badge logic for bottom nav entirely or keep it for index -1.
                    iconWidget = Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 24.w,
                      color: isSelected
                          ? selectedColor
                          : context.colorTextMuted,
                    );
                  } else {
                    iconWidget = Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 24.w,
                      color: isSelected
                          ? selectedColor
                          : context.colorTextMuted,
                    );
                  }

                  return Expanded(
                    child: Semantics(
                      label: item.label,
                      selected: isSelected,
                      button: true,
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              iconWidget,
                              SizedBox(height: 4.h),
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 200),
                                style: (isSelected
                                    ? AppTextStyles.labelSmall.copyWith(
                                        color: selectedColor,
                                        fontWeight: FontWeight.w700,
                                      )
                                    : AppTextStyles.labelSmall.copyWith(
                                        color: context.colorTextMuted,
                                      )),
                                child: Text(item.label),
                              ),
                              // Active indicator dot
                              AnimatedContainer(
                                duration: Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                margin: EdgeInsets.only(top: 4),
                                width: isSelected ? 4 : 0,
                                height: isSelected ? 4 : 0,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
