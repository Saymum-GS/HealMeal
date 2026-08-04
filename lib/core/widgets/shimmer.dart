import 'package:flutter/material.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HmShimmer extends StatefulWidget {
  const HmShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<HmShimmer> createState() => _HmShimmerState();
}

class _HmShimmerState extends State<HmShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : context.colorBorder;
    final subtleColor = isDark ? AppColors.darkSurface : AppColors.subtle;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 4), 0.0),
              end: Alignment(0.0 + (_controller.value * 4), 0.0),
              colors: [
                borderColor.withOpacity(0.4),
                subtleColor,
                borderColor.withOpacity(0.4),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class HmProductCardShimmer extends StatelessWidget {
  const HmProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HmShimmer(width: double.infinity, height: 92.h),
          SizedBox(height: 8.h),
          HmShimmer(
            width: 80.w,
            height: 16.h,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(height: 8.h),
          HmShimmer(width: double.infinity, height: 14.h),
          SizedBox(height: 4.h),
          HmShimmer(width: 100.w, height: 12.h),
          Spacer(),
          HmShimmer(width: 60.w, height: 20.h),
          SizedBox(height: 8.h),
          HmShimmer(
            width: double.infinity,
            height: 34.h,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
        ],
      ),
    );
  }
}
