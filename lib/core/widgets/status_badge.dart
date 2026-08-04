import 'package:flutter/material.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    if (normalized.contains('deliver')) {
      bg = AppColors.successBg;
      fg = AppColors.success;
    } else if (normalized.contains('cancel')) {
      bg = AppColors.errorBg;
      fg = AppColors.error;
    } else if (normalized.contains('dispatch') || normalized.contains('out')) {
      bg = AppColors.infoBg;
      fg = AppColors.info;
    } else if (normalized.contains('process') ||
        normalized.contains('confirm')) {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
    } else {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.4,
        ),
        border: Border.all(color: fg.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: fg.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            status,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
