import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LabReportsScreen extends StatelessWidget {
  const LabReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AppSession.userId;
    if (userId == null) {
      return Scaffold(
        appBar: HealMealAppBar(title: 'My Lab Reports', showBack: true),
        body: Center(child: Text('Please login to see your reports')),
      );
    }

    return Scaffold(
      appBar: HealMealAppBar(title: 'My Lab Reports', showBack: true),
      body: StreamBuilder<List<LabBooking>>(
        stream: LabRepository().watchUserBookings(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final reports = (snapshot.data ?? [])
              .where(
                (b) =>
                    b.status == LabBookingStatus.resultReady ||
                    b.reportUrl != null,
              )
              .toList();

          if (reports.isEmpty) {
            return EmptyStateWidget(
              type: EmptyStateType.labTests,
              customTitle: 'No reports yet',
              customBody:
                  'Your lab test reports will appear here after completion.',
              actionLabel: 'Book a Lab Test',
              onAction: () => context.go('/labs'),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: reports.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final report = reports[index];
              return Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: AppRadius.lg,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.science_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(report.testName, style: AppTextStyles.h3),
                          Text(
                            'Patient: ${report.patientName}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.colorTextSecondary,
                            ),
                          ),
                          Text(
                            AppFormatters.longDate(report.selectedDate),
                            style: AppTextStyles.bodyXSmall.copyWith(
                              color: context.colorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _viewReport(context, report.reportUrl),
                      icon: Icon(Icons.picture_as_pdf_outlined, size: 16.w),
                      label: Text('View PDF'),
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

  void _viewReport(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open report.')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid report link.')));
    }
  }
}
