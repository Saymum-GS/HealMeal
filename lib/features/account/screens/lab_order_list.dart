import 'package:flutter/material.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../orders/orders_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LabOrderList extends StatelessWidget {
  const LabOrderList({super.key, required this.items});

  final List<LabBooking> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateWidget(type: EmptyStateType.orders);
    }
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        final item = items[index];
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.lg,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(item.id, style: AppTextStyles.labelLarge),
                  ),
                  Text(
                    AppFormatters.longDate(item.createdAt),
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: context.colorTextSecondary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  StatusBadge(status: item.status.name),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Text(item.testName, style: AppTextStyles.h3),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Patient: ${item.patientName} | ${item.age}${item.gender.isNotEmpty ? item.gender[0] : ''}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colorTextSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Sample Collection: ${item.timeSlot}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (item.addressText != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Address: ${item.addressText}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colorTextSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.xl),
              Row(
                children: <Widget>[
                  if (item.status == LabBookingStatus.upcoming)
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await context.read<OrdersCubit>().cancelLabBooking(item.id);
                          if (context.mounted) {
                            AppToast.show(
                              context,
                              'Booking cancelled successfully',
                              type: ToastType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppToast.show(
                              context,
                              'Failed to cancel booking: $e',
                              type: ToastType.error,
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.cancel_outlined, size: 16.w),
                      label: Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    )
                  else if (item.status == LabBookingStatus.cancelled)
                    TextButton.icon(
                      onPressed: () {
                        AppToast.show(
                          context,
                          'Cannot remove demo lab orders.',
                          type: ToastType.info,
                        ); // Wait, this can be implemented in OrdersCubit later. For now hide.
                      },
                      icon: Icon(Icons.delete_outline, size: 16.w),
                      label: Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                    ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      if (item.status == LabBookingStatus.completed) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => Container(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 64.w,
                                  color: Colors.red,
                                ),
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  '${item.testName} Report',
                                  style: AppTextStyles.h2,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Patient: ${item.patientName}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                SizedBox(height: AppSpacing.xl),
                                HealMealButton(
                                  label: 'View PDF in Browser',
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    if (item.reportUrl != null && item.reportUrl!.isNotEmpty) {
                                      try {
                                        final uri = Uri.parse(item.reportUrl!);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Could not open report link',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Invalid report link',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Report not available yet',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      item.status == LabBookingStatus.completed
                          ? 'View Report'
                          : 'View Booking',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
