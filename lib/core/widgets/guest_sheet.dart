import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showGuestAccountSheet(BuildContext context, {String? customMessage}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.all(24.0.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle, size: 64.w, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text('Your HealMeal Account', style: AppTextStyles.h2),
            SizedBox(height: 8.h),
            Text(
              customMessage ??
                  'Sign in to track orders, save prescriptions, access lab reports, and get exclusive offers.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
                child: Text('Sign In'),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/register');
                },
                child: Text('Create Account'),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continue browsing as guest'),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      );
    },
  );
}
