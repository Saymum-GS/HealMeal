import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/utils.dart';
import '../../../../core/widgets.dart';
import '../admin_cubit.dart';

class _AdvancedLabBookingEditDialog extends StatefulWidget {
  final LabBooking booking;
  const _AdvancedLabBookingEditDialog(this.booking);

  @override
  State<_AdvancedLabBookingEditDialog> createState() =>
      _AdvancedLabBookingEditDialogState();
}

class _AdvancedLabBookingEditDialogState
    extends State<_AdvancedLabBookingEditDialog> {
  late TextEditingController slotCtrl;
  late TextEditingController reasonCtrl;
  String? reportBase64;

  @override
  void initState() {
    super.initState();
    slotCtrl = TextEditingController(text: widget.booking.assignedSlot);
    reasonCtrl = TextEditingController(text: widget.booking.cancellationReason);
    reportBase64 = widget.booking.reportBase64;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Lab Booking', style: AppTextStyles.h2),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HealMealTextField(controller: slotCtrl, label: 'Assigned Slot'),
            SizedBox(height: AppSpacing.sm),
            HealMealTextField(
              controller: reasonCtrl,
              label: 'Cancellation Reason',
              maxLines: 2,
            ),
            SizedBox(height: AppSpacing.sm),
            Text('Report', style: AppTextStyles.h3),
            if (reportBase64 != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text('Report uploaded (Base64)'),
            ],
            HealMealButton(
              type: ButtonType.text,
              prefixIcon: Icons.upload_file,
              label: 'Upload Report (Image Base64)',
              onPressed: () async {
                final b64 = await ImageUploadUtil.pickImageAsBase64();
                if (b64 == 'TOO_LARGE') {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Image exceeds the allowed limit.'),
                      ),
                    );
                  }
                  return;
                }
                if (b64 != null) {
                  setState(() => reportBase64 = b64);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        HealMealButton(
          type: ButtonType.text,
          onPressed: () => Navigator.pop(context),
          label: 'Cancel',
        ),
        HealMealButton(
          onPressed: () async {
            LabBookingStatus? newStatus;
            if (reportBase64 != null &&
                reportBase64 != widget.booking.reportBase64) {
              newStatus = LabBookingStatus.resultReady;
            }
            try {
              await context.read<AdminLabBookingCubit>().updateAdvancedBookingFields(
                widget.booking.id,
                reportBase64: reportBase64,
                assignedSlot: slotCtrl.text.isEmpty ? null : slotCtrl.text,
                cancellationReason: reasonCtrl.text.isEmpty
                    ? null
                    : reasonCtrl.text,
                status: newStatus,
              );
              if (context.mounted) {
                Navigator.pop(context);
                AppToast.show(context, 'Booking updated.', type: ToastType.success);
              }
            } catch (e) {
              if (context.mounted) {
                AppToast.show(context, 'Failed to save booking: $e', type: ToastType.error);
              }
            }
          },
          label: 'Save',
        ),
      ],
    );
  }
}

class AdminLabBookingScreen extends StatelessWidget {
  const AdminLabBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Lab Bookings', showBack: true),
      body: BlocBuilder<AdminLabBookingCubit, AdminLabBookingState>(
        builder: (context, state) {
          if (state.labBookings.isEmpty) {
            return Center(child: Text("No lab bookings yet."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: state.labBookings.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final booking = state.labBookings[index];
              return Card(
                child: ListTile(
                  title: Text(booking.testName, style: AppTextStyles.h3),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Patient: ${booking.patientName} (${booking.age}, ${booking.gender})",
                      ),
                      Text(
                        "Date: ${AppFormatters.compactDateTime(booking.selectedDate)}",
                      ),
                      Text("Slot: ${booking.timeSlot}"),
                      if (booking.addressText != null)
                        Text(
                          "Address: ${booking.addressText}",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                _AdvancedLabBookingEditDialog(booking),
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: StatusBadge(status: booking.status.name),
                        onSelected: (newStatusName) {
                          final newStatus = LabBookingStatus.values.firstWhere(
                            (s) => s.name == newStatusName,
                            orElse: () => booking.status,
                          );
                          context
                              .read<AdminLabBookingCubit>()
                              .updateBookingStatus(booking.id, newStatus);
                          AppToast.show(
                            context,
                            'Status updated.',
                            type: ToastType.success,
                          );
                        },
                        itemBuilder: (context) => LabBookingStatus.values
                            .map(
                              (s) => PopupMenuItem(
                                value: s.name,
                                child: Text(s.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
