import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models.dart';
import '../../../../core/config.dart';
import '../../../../core/utils.dart';
import '../../../../core/repositories.dart';
import '../../../../core/services.dart';
import '../../../../core/widgets.dart';
import '../cubits/admin_lab_package_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminLabPackagesScreen extends StatelessWidget {
  const AdminLabPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminLabPackageCubit(getIt<LabTestRepository>())..startWatching(),
      child: const _LabPackagesView(),
    );
  }
}

Widget _buildSafeImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: AppColors.subtle,
      child: Icon(Icons.image),
    );
  }
  return Image.memory(
    ImageUploadUtil.base64ToImage(url) ?? Uint8List(0),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (c, e, s) => Container(
      width: width,
      height: height,
      color: AppColors.subtle,
      child: Icon(Icons.broken_image),
    ),
  );
}

class _LabPackagesView extends StatelessWidget {
  const _LabPackagesView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminLabPackageCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text('Lab Packages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageForm(context, null),
        icon: Icon(Icons.add_rounded),
        label: Text('Add Package'),
      ),
      body: switch (state) {
        AdminLabPackageInitial() ||
        AdminLabPackageLoading() => Center(child: CircularProgressIndicator()),
        AdminLabPackageError(message: final m) => Center(
          child: Text('Error: $m'),
        ),
        AdminLabPackageLoaded(packages: final packages) =>
          packages.isEmpty
              ? Center(child: Text('No packages found.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.w),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildSafeImage(
                            package.imageUrl,
                            width: 60.w,
                            height: 60.h,
                          ),
                        ),
                        title: Text(
                          package.name,
                          style: AppTextStyles.labelLarge,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MRP: ৳${package.mrp} • Sale: ৳${package.salePrice}',
                              style: AppTextStyles.bodySmall,
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: package.isActive
                                        ? AppColors.success
                                        : AppColors.subtle,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    package.isActive ? 'Active' : 'Draft',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: package.isActive
                                          ? Colors.white
                                          : AppColors.secondary,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showPackageForm(context, package);
                            } else if (value == 'delete') {
                              _confirmDelete(context, package);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: AppColors.accentBlue,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    color: AppColors.error,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
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
        _ => Center(child: Text('Unknown state')),
      },
    );
  }

  void _showPackageForm(BuildContext context, LabPackage? package) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminLabPackageCubit>(),
        child: _PackageFormDialog(package: package),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LabPackage package) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Package'),
        content: Text('Are you sure you want to delete "${package.name}"?'),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(ctx),
            label: 'Cancel',
          ),
          HealMealButton(
            type: ButtonType.text,
            foregroundColor: AppColors.error,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AdminLabPackageCubit>().deletePackage(package.id);
                if (context.mounted) {
                  AppToast.show(
                    context,
                    'Package deleted',
                    type: ToastType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(
                    context,
                    'Failed to delete package: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
            label: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _PackageFormDialog extends StatefulWidget {
  final LabPackage? package;
  const _PackageFormDialog({this.package});
  @override
  _PackageFormDialogState createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<_PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _salePriceCtrl;
  late TextEditingController _testIdsCtrl;

  bool _isActive = true;
  String _imageUrl = '';
  bool _isLoading = false;
  late String _packageId;

  @override
  void initState() {
    super.initState();
    _packageId =
        widget.package?.id ?? getIt<LabTestRepository>().generatePackageId();
    _nameCtrl = TextEditingController(text: widget.package?.name ?? '');
    _descCtrl = TextEditingController(text: widget.package?.description ?? '');
    _mrpCtrl = TextEditingController(
      text: (widget.package?.mrp ?? 0).toString(),
    );
    _salePriceCtrl = TextEditingController(
      text: (widget.package?.salePrice ?? 0).toString(),
    );
    _testIdsCtrl = TextEditingController(
      text: (widget.package?.testIds ?? []).join(', '),
    );

    _isActive = widget.package?.isActive ?? true;
    _imageUrl = widget.package?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _mrpCtrl.dispose();
    _salePriceCtrl.dispose();
    _testIdsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final base64String = await ImageUploadUtil.pickImageAsBase64();
    if (base64String == 'TOO_LARGE') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image exceeds the allowed limit.')),
        );
      }
      return;
    }
    if (base64String != null && mounted) {
      setState(() => _imageUrl = base64String);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final package = LabPackage(
        id: _packageId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        testIds: _testIdsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        mrp: double.tryParse(_mrpCtrl.text) ?? 0,
        salePrice: double.tryParse(_salePriceCtrl.text) ?? 0,
        imageUrl: _imageUrl,
        isActive: _isActive,
      );

      if (widget.package == null) {
        await getIt<LabTestRepository>().addLabPackage(package);
      } else {
        await getIt<LabTestRepository>().updateLabPackage(package);
      }

      if (mounted) {
        Navigator.pop(context);
        AppToast.show(context, 'Saved successfully', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.package == null ? 'Add Package' : 'Edit Package',
                style: AppTextStyles.h2,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HealMealTextField(
                        controller: _nameCtrl,
                        label: 'Name',
                        validator: AppValidators.requiredField,
                      ),
                      SizedBox(height: 16.h),
                      HealMealTextField(
                        controller: _descCtrl,
                        label: 'Description',
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: HealMealTextField(
                              controller: _mrpCtrl,
                              label: 'MRP',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: HealMealTextField(
                              controller: _salePriceCtrl,
                              label: 'Sale Price',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      HealMealTextField(
                        controller: _testIdsCtrl,
                        label: 'Test IDs (comma separated)',
                        maxLines: 2,
                      ),
                      SizedBox(height: 8.h),
                      SwitchListTile(
                        title: Text('Is Active'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SizedBox(height: 16.h),
                      Text('Image (Base64)', style: AppTextStyles.labelMedium),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 150.h,
                          decoration: BoxDecoration(
                            color: AppColors.subtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colorBorder),
                          ),
                          child: _imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildSafeImage(
                                    _imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40.w,
                                      color: context.colorTextMuted,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Upload Image',
                                      style: TextStyle(
                                        color: context.colorTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HealMealButton(
                    type: ButtonType.text,
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    label: 'Cancel',
                  ),
                  SizedBox(width: 12.w),
                  HealMealButton(
                    onPressed: _isLoading ? null : _save,
                    isLoading: _isLoading,
                    label: 'Save',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
