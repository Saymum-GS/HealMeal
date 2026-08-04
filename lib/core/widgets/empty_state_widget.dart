import 'buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.type,
    this.customTitle,
    this.customBody,
    this.onAction,
    this.actionLabel,
  });

  final EmptyStateType type;
  final String? customTitle;
  final String? customBody;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String body) = switch (type) {
      EmptyStateType.cart => (
        Icons.shopping_cart_outlined,
        'Your cart is empty',
        'Browse medicines and healthcare products',
      ),
      EmptyStateType.orders => (
        Icons.receipt_long_outlined,
        'No orders yet',
        'Your placed orders will appear here',
      ),
      EmptyStateType.search => (
        Icons.search_off_rounded,
        'No results found',
        'Try a different keyword',
      ),
      EmptyStateType.notifications => (
        Icons.notifications_none_rounded,
        'No notifications yet',
        'We will keep you posted here',
      ),
      EmptyStateType.prescriptions => (
        Icons.description_outlined,
        'No prescriptions yet',
        'Upload a prescription to get started',
      ),
      EmptyStateType.labTests => (
        Icons.science_outlined,
        'No reports yet',
        'Book a lab test to see results here',
      ),
      EmptyStateType.chat => (
        Icons.chat_bubble_outline_rounded,
        'No messages yet',
        'Send a message to start the conversation',
      ),
      EmptyStateType.address => (
        Icons.location_off_rounded,
        'No saved addresses',
        'Add a delivery address to continue',
      ),
      EmptyStateType.error => (
        Icons.error_outline_rounded,
        'Something went wrong',
        'An error occurred while loading data',
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
                child: Center(
                  child: Icon(icon, size: 36.w, color: AppColors.primary)
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .moveY(
                        begin: -5,
                        end: 5,
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                customTitle ?? title,
                style: AppTextStyles.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  customBody ?? body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colorTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (onAction != null) ...[
                SizedBox(height: 24.h),
                SizedBox(
                  width: 200.w,
                  child: HealMealButton(
                    label: actionLabel ?? 'Continue',
                    onPressed: onAction,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum EmptyStateType {
  cart,
  orders,
  search,
  notifications,
  prescriptions,
  labTests,
  chat,
  address,
  error,
}
