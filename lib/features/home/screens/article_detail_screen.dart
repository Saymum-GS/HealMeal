import 'package:flutter/material.dart';

import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: article.title, showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              HealMealImage(
                imageUrl: article.imageUrl,
                height: 200.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: AppTextStyles.h1),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 16.w,
                        color: context.colorTextSecondary,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(article.category, style: AppTextStyles.bodySmall),
                      SizedBox(width: AppSpacing.lg),
                      Icon(
                        Icons.timer,
                        size: 16.w,
                        color: context.colorTextSecondary,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '${article.readTimeMinutes} min read',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(article.body, style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
