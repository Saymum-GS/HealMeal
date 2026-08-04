import 'package:flutter/material.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.showSeeAll = true,
    this.trailing,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final bool showSeeAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: AppTextStyles.h2)),
        if (trailing != null) ...<Widget>[trailing!, SizedBox(width: 8.w)],
        if (showSeeAll && onSeeAll != null)
          TextButton.icon(
            onPressed: onSeeAll,
            icon: Icon(Icons.arrow_forward_ios_rounded, size: 14.w),
            label: Text(
              'See All',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
