import 'package:flutter/material.dart';
import '../../../core/config.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../core/services.dart';
import '../../account/account_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Reviews')),
      body: StreamBuilder<List<Review>>(
        stream: getIt<ReviewRepository>().watchAllReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return Center(child: Text('No reviews found.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return CardSection(
                title:
                    '${review.targetType.toUpperCase()} - ${review.targetId}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'By: ${review.userName}',
                          style: AppTextStyles.labelMedium,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: review.status == 'approved'
                                ? AppColors.successBg
                                : AppColors.warningBg,
                            borderRadius: AppRadius.sm,
                          ),
                          child: Text(
                            review.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: review.status == 'approved'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.accentGold,
                          size: 20.w,
                        );
                      }),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(review.comment),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (review.status != 'approved')
                          TextButton(
                            onPressed: () async {
                              try {
                                await getIt<ReviewRepository>().updateReviewStatus(review.id, 'approved');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            child: Text(
                              'Approve',
                              style: TextStyle(color: AppColors.success),
                            ),
                          ),
                        if (review.status != 'rejected')
                          TextButton(
                            onPressed: () async {
                              try {
                                await getIt<ReviewRepository>().updateReviewStatus(review.id, 'rejected');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            child: Text(
                              'Reject',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () async {
                            try {
                              await getIt<ReviewRepository>().deleteReview(review.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support Tickets')),
      body: StreamBuilder<List<SupportMessage>>(
        stream: getIt<SupportRepository>().watchAllSupportMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return Center(child: Text('No support tickets found.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: messages.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final message = messages[index];
              return CardSection(
                title: '${message.type.toUpperCase()} - ${message.subject}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: ${message.userName}',
                              style: AppTextStyles.labelMedium,
                            ),
                            Text(
                              'Email: ${message.email}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Phone: ${message.phone}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: message.status == 'resolved'
                                ? AppColors.successBg
                                : AppColors.errorBg,
                            borderRadius: AppRadius.sm,
                          ),
                          child: Text(
                            message.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: message.status == 'resolved'
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(message.message),
                    if (message.reply != null && message.reply!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.md),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.subtle,
                          borderRadius: AppRadius.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Reply:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4.h),
                            Text(message.reply!),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.status != 'resolved')
                          TextButton(
                            onPressed: () {
                              _showReplyDialog(context, message);
                            },
                            child: Text(
                              'Reply & Resolve',
                              style: TextStyle(color: AppColors.success),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () async {
                            try {
                              await getIt<SupportRepository>().deleteSupportMessage(message.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showReplyDialog(BuildContext context, SupportMessage message) {
    final controller = TextEditingController(text: message.reply);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reply to Ticket'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(hintText: 'Enter your reply...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await getIt<SupportRepository>().updateSupportMessageStatus(
                    message.id,
                    'resolved',
                    reply: controller.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error resolving ticket: $e')),
                    );
                  }
                }
              },
              child: Text('Resolve'),
            ),
          ],
        );
      },
    );
  }
}
