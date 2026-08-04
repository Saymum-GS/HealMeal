import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/widgets.dart';
import '../../core/utils.dart';
import '../auth/auth_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LabPackageDetailScreen extends StatelessWidget {
  final LabPackage package;

  const LabPackageDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: package.name, showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.imageUrl.isNotEmpty)
              HealMealImage(
                imageUrl: package.imageUrl,
                height: 200.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(package.name, style: AppTextStyles.h1),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (package.mrp > package.salePrice)
                            Text(
                              AppFormatters.taka(package.mrp),
                              style: AppTextStyles.bodyMedium.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: context.colorTextSecondary,
                              ),
                            ),
                          Text(
                            AppFormatters.taka(package.salePrice),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(package.description, style: AppTextStyles.bodyMedium),
                  SizedBox(height: AppSpacing.lg),
                  if (package.testIds.isNotEmpty) ...[
                    Text('Included Tests', style: AppTextStyles.h2),
                    SizedBox(height: AppSpacing.sm),
                    ...package.testIds.map(
                      (t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                        title: Text(t),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final isGuest =
                            context.read<AuthCubit>().state
                                is AuthUnauthenticated;
                        if (isGuest) {
                          showGuestAccountSheet(
                            context,
                            customMessage:
                                'Sign in to book a lab test and view your reports.',
                          );
                          return;
                        }
                        context.push('/labs/book/${package.id}');
                      },
                      child: Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
