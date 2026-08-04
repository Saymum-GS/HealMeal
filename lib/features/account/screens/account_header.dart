import 'package:flutter/material.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({
    super.key,
    required this.name,
    required this.email,
    required this.onEdit,
    this.photoUrl,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96.w,
                height: 96.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 84.w,
                height: 84.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                      ? ImageBase64Util.resolveProvider(photoUrl!)
                      : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 36.w,
                        )
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  name,
                  style: AppTextStyles.h1.copyWith(color: AppColors.white),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.white),
                    shape: StadiumBorder(),
                  ),
                  child: Text('Edit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
