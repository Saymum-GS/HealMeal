import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReferAndEarnScreen extends StatelessWidget {
  const ReferAndEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String referralCode = 'HEAL-A7F3K2';
    return Scaffold(
      appBar: HealMealAppBar(title: 'Refer and Earn', showBack: true),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              48,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 64.w,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Refer a Friend,\nEarn ${AppFormatters.taka(50)}!',
                  style: AppTextStyles.displayHero.copyWith(
                    color: AppColors.white,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Your friend gets ${AppFormatters.taka(30)} off their first order.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, -20),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  children: <Widget>[
                    Text(
                      'Your Referral Code',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.lg,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        referralCode,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.priceLarge.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 6,
                          fontSize: 28.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: HealMealButton(
                            label: 'Copy Code',
                            type: ButtonType.outlined,
                            size: ButtonSize.medium,
                            prefixIcon: Icons.copy_rounded,
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: referralCode),
                              );
                              if (context.mounted) {
                                AppToast.show(
                                  context,
                                  'Code copied!',
                                  type: ToastType.success,
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: HealMealButton(
                            label: 'Share',
                            size: ButtonSize.medium,
                            prefixIcon: Icons.share_rounded,
                            onPressed: () {
                              Share.share(
                                'Join HealMeal with code $referralCode and save on your first healthcare order.',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),
                    SizedBox(height: 12.h),
                    SizedBox(height: AppSpacing.lg),
                    Text('How it works', style: AppTextStyles.h2),
                    SizedBox(height: AppSpacing.md),
                    _StepCard(
                      step: '1',
                      title: 'Invite Friends',
                      body: 'Share your code with friends.',
                    ),
                    SizedBox(height: AppSpacing.md),
                    _StepCard(
                      step: '2',
                      title: 'They Register',
                      body: 'They use your code during signup.',
                    ),
                    SizedBox(height: AppSpacing.md),
                    _StepCard(
                      step: '3',
                      title: 'Get Reward',
                      body:
                          'Earn cashback when they complete their first order.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.body,
  });
  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text(
            step,
            style: TextStyle(fontSize: 12.sp, color: AppColors.white),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              Text(body, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
