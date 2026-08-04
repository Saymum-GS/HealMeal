import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';
import '../../../../core/config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminPrescriptionsScreen extends StatelessWidget {
  const AdminPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Prescription Review', showBack: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prescriptions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return EmptyStateWidget(
              type: EmptyStateType.orders,
              customTitle: 'No Prescriptions',
              customBody: 'There are no prescriptions to review.',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final p = AppPrescription.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return _PrescriptionCard(prescription: p);
            },
          );
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final AppPrescription prescription;

  const _PrescriptionCard({required this.prescription});

  Future<void> _updateStatus(
    BuildContext context,
    PrescriptionStatus newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(prescription.id)
          .update({'status': newStatus.name});
      if (context.mounted) {
        AppToast.show(
          context,
          'Status updated to ${newStatus.label}',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          context,
          'Error updating status: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User: ${prescription.userId.substring(0, 5)}...',
                  style: AppTextStyles.labelLarge,
                ),
                _StatusChip(status: prescription.status),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Date: ${AppFormatters.compactDateTime(prescription.createdAt)}',
              style: AppTextStyles.bodySmall,
            ),
            if (prescription.notes.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                'Notes: ${prescription.notes}',
                style: AppTextStyles.bodySmall,
              ),
            ],
            SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: EdgeInsets.all(16.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        child: Image.memory(
                          ImageBase64Util.decode(prescription.imageBase64),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  ImageBase64Util.decode(prescription.imageBase64),
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (prescription.status == PrescriptionStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: HealMealButton(
                      type: ButtonType.outlined,
                      onPressed: () =>
                          _updateStatus(context, PrescriptionStatus.rejected),
                      foregroundColor: AppColors.error,
                      label: 'Reject',
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: HealMealButton(
                      onPressed: () =>
                          _updateStatus(context, PrescriptionStatus.approved),
                      backgroundColor: AppColors.success,
                      label: 'Approve',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PrescriptionStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case PrescriptionStatus.pending:
        color = AppColors.warning;
        break;
      case PrescriptionStatus.approved:
        color = AppColors.success;
        break;
      case PrescriptionStatus.rejected:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
