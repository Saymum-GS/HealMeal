import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/widgets.dart';
import '../../core/utils.dart';
import '../../core/services.dart';
import '../../core/repositories.dart';
import 'prescription_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrescriptionUploadScreen extends StatelessWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrescriptionCubit(getIt<PrescriptionRepository>()),
      child: const _PrescriptionUploadView(),
    );
  }
}

class _PrescriptionUploadView extends StatefulWidget {
  const _PrescriptionUploadView();

  @override
  State<_PrescriptionUploadView> createState() =>
      _PrescriptionUploadViewState();
}

class _PrescriptionUploadViewState extends State<_PrescriptionUploadView> {
  String? _imageBase64;
  final _notesController = TextEditingController();

  Future<void> _pickImage() async {
    final base64 = await ImageBase64Util.pickAndEncode(
      maxWidth: 800,
      maxHeight: 800,
      quality: 60,
    );
    if (base64 == 'TOO_LARGE') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image is too large. Please select a smaller image.'),
          ),
        );
      }
      return;
    }
    if (base64 != null) {
      setState(() {
        _imageBase64 = base64;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Upload Prescription', showBack: true),
      body: BlocConsumer<PrescriptionCubit, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Prescription uploaded successfully!')),
            );
            context.pop(state.prescription.id);
          } else if (state is PrescriptionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
          }
        },
        builder: (context, state) {
          final isLoading = state is PrescriptionLoading;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 32.w,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        "Upload your prescription. Our pharmacists will review it and match the medicines to your order.",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageBase64 == null
                          ? context.colorBorder
                          : AppColors.primary,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageBase64 == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 48.w,
                              color: AppColors.subtle,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap to take photo or choose from gallery',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.colorTextSecondary,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            ImageBase64Util.decode(_imageBase64!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              HealMealTextField(
                controller: _notesController,
                label: 'Notes for Pharmacist (Optional)',
                hint: 'Any specific instructions...',
                maxLines: 3,
                readOnly: isLoading,
              ),
              SizedBox(height: AppSpacing.xxl),
              HealMealButton(
                label: 'Submit Prescription',
                isLoading: isLoading,
                onPressed: _imageBase64 == null
                    ? null
                    : () {
                        final userId = AppSession.userId;
                        if (userId != null) {
                          context.read<PrescriptionCubit>().uploadPrescription(
                            userId,
                            _imageBase64!,
                            _notesController.text,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('You must be logged in.')),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
