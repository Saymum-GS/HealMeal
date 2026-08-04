import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _SkeletonBase extends StatelessWidget {
  const _SkeletonBase({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurface : AppColors.subtle,
      highlightColor: isDark ? context.colorCard : AppColors.white,
      child: child,
    );
  }
}

class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? context.colorCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : context.colorBorder;

    return _SkeletonBase(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: bgColor, borderRadius: AppRadius.md),
        child: Column(
          children: [
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: AppRadius.md,
              ),
            ),
            SizedBox(height: 12.h),
            Container(height: 12.h, color: borderColor),
            SizedBox(height: 8.h),
            Container(height: 12.h, width: 100.w, color: borderColor),
            Spacer(),
            Container(
              height: 36.h,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: AppRadius.md,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : context.colorBorder;

    return _SkeletonBase(
      child: ListTile(
        title: SizedBox(
          height: 12.h,
          child: ColoredBox(color: borderColor),
        ),
        subtitle: SizedBox(
          height: 12.h,
          child: ColoredBox(color: borderColor),
        ),
      ),
    );
  }
}

class SkeletonLabTestCard extends StatelessWidget {
  const SkeletonLabTestCard({super.key});

  @override
  Widget build(BuildContext context) => SkeletonOrderCard();
}

class SkeletonNotificationItem extends StatelessWidget {
  const SkeletonNotificationItem({super.key});

  @override
  Widget build(BuildContext context) => SkeletonOrderCard();
}
