import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import '../../../core/models.dart';
import '../notification_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final notifications = state.notifications;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
            title: Text('Notifications'),
            actions: <Widget>[
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () {
                    context.read<NotificationCubit>().markAllAsRead();
                  },
                  child: Text('Mark all read'),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Wait a bit to simulate refresh since Firestore streams are real-time anyway
              await Future<void>.delayed(Duration(milliseconds: 800));
            },
            child: notifications.isEmpty
                ? EmptyStateWidget(type: EmptyStateType.notifications)
                : ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int index) {
                      final AppNotification item = notifications[index];
                      final Color accent = switch (item.type) {
                        'order' => AppColors.primary,
                        'prescription' => AppColors.warning,
                        'lab' => AppColors.accentBlue,
                        _ => AppColors.accentOrange,
                      };
                      return InkWell(
                        onTap: () {
                          if (!item.read) {
                            context.read<NotificationCubit>().markAsRead(
                              item.id,
                            );
                          }
                        },
                        borderRadius: AppRadius.lg,
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: item.read
                                ? Theme.of(context).cardColor
                                : AppColors.primaryLight,
                            borderRadius: AppRadius.lg,
                            border: Border(
                              left: BorderSide(
                                color: item.read
                                    ? Colors.transparent
                                    : AppColors.primary,
                                width: 3.w,
                              ),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: accent.withOpacity(.12),
                                child: Icon(
                                  _iconForType(item.type),
                                  color: accent,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.title,
                                      style: AppTextStyles.h3.copyWith(
                                        fontWeight: item.read
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      item.body,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      AppFormatters.compactDateTime(item.time),
                                      style: AppTextStyles.bodyXSmall.copyWith(
                                        color: context.colorTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_outlined;
      case 'prescription':
        return Icons.description_outlined;
      case 'lab':
        return Icons.science_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }
}
