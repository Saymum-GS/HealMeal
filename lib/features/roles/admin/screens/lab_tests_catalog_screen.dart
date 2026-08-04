import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/utils.dart';
import '../../../../core/widgets.dart';
import '../../../../core/services.dart';
import '../../../../core/repositories.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// -- Admin Lab Tests Catalog Screen -------------------------------------------

class AdminLabTestsCatalogScreen extends StatelessWidget {
  const AdminLabTestsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Lab Tests Catalog', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => AdminLabTestFormScreen())),
        icon: Icon(Icons.add),
        label: Text('Add Lab Test'),
      ),
      body: StreamBuilder<List<LabTest>>(
        stream: getIt<LabTestRepository>().watchLabTests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 48.w),
                  SizedBox(height: 8.h),
                  Text('Error loading lab tests', style: AppTextStyles.h3),
                  SizedBox(height: 4.h),
                  Text(
                    '${snapshot.error}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final tests = snapshot.data!;

          if (tests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.biotech_outlined,
                    size: 80.w,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                  SizedBox(height: 16.h),
                  Text('No lab tests in catalog.', style: AppTextStyles.h3),
                  SizedBox(height: 8.h),
                  Text(
                    'Tap the + button to add your first lab test.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 56.w,
                    height: 56.h,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: test.imageUrl.isNotEmpty
                          ? HealMealImage(
                              imageUrl: test.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.primaryLight.withOpacity(0.2),
                              child: Icon(
                                Icons.biotech_rounded,
                                size: 32.w,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(test.name, style: AppTextStyles.labelLarge),
                      ),
                      if (test.isPopular)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Popular',
                            style: AppTextStyles.bodyXSmall.copyWith(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MRP: ${AppFormatters.taka(test.mrp)} | Sale: ${AppFormatters.taka(test.salePrice)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                test.isAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 12.w,
                                color: test.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                test.isAvailable ? 'Available' : 'Unavailable',
                                style: AppTextStyles.bodyXSmall.copyWith(
                                  color: test.isAvailable
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          if (test.isHomeCollection)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.home,
                                  size: 12.w,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Home Collection',
                                  style: AppTextStyles.bodyXSmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminLabTestFormScreen(existing: test),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, test);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
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
                              Icons.delete_outline,
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
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LabTest test) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Lab Test?'),
        content: Text(
          'Are you sure you want to delete "${test.name}"? This cannot be undone.',
        ),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(ctx, false),
            label: 'Cancel',
          ),
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Delete',
            foregroundColor: AppColors.error,
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await getIt<LabTestRepository>().deleteLabTest(test.id);
        if (context.mounted) {
          AppToast.show(
            context,
            'Lab test deleted successfully',
            type: ToastType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, 'Failed to delete: $e', type: ToastType.error);
        }
      }
    }
  }
}

// -- Admin Lab Test Form Screen (Full-Screen per spec Section 5.3) -------------------

class AdminLabTestFormScreen extends StatefulWidget {
  const AdminLabTestFormScreen({super.key, this.existing});
  final LabTest? existing;

  @override
  State<AdminLabTestFormScreen> createState() => _AdminLabTestFormScreenState();
}

class _AdminLabTestFormScreenState extends State<AdminLabTestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _mrpC;
  late final TextEditingController _salePriceC;
  late final TextEditingController _reportHoursC;
  late final TextEditingController _preparationC;
  late final TextEditingController _includesC;

  late final String _targetTestId;
  String? _imageUrl;
  bool _isAvailable = true;
  bool _isPopular = false;
  bool _isHomeCollection = true;
  String _category = 'General';
  bool _saving = false;

  static const _labCategories = [
    'General',
    'Haematology',
    'Biochemistry',
    'Microbiology',
    'Immunology',
    'Radiology',
    'Cardiology',
    'Diabetes',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _targetTestId = e?.id ?? getIt<LabTestRepository>().generateId();
    _nameC = TextEditingController(text: e?.name ?? '');
    _mrpC = TextEditingController(text: e?.mrp.toString() ?? '');
    _salePriceC = TextEditingController(text: e?.salePrice.toString() ?? '');
    _reportHoursC = TextEditingController(text: e?.reportHours ?? '');
    _preparationC = TextEditingController(text: e?.preparation ?? '');
    _includesC = TextEditingController(text: e?.includes.join(', ') ?? '');
    _imageUrl = e?.imageUrl;
    _isAvailable = e?.isAvailable ?? true;
    _isPopular = e?.isPopular ?? false;
    _isHomeCollection = e?.isHomeCollection ?? true;
    _category = e?.category ?? 'General';
  }

  @override
  void dispose() {
    _nameC.dispose();
    _mrpC.dispose();
    _salePriceC.dispose();
    _reportHoursC.dispose();
    _preparationC.dispose();
    _includesC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final mrp = double.tryParse(_mrpC.text) ?? 0.0;
    final salePrice = double.tryParse(_salePriceC.text) ?? mrp;
    final discount = mrp > 0 ? (((mrp - salePrice) / mrp) * 100).round() : 0;
    final includes = _includesC.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'id': _targetTestId,
      'name': _nameC.text.trim(),
      'slug': _nameC.text.trim().toLowerCase().replaceAll(' ', '-'),
      'mrp': mrp,
      'salePrice': salePrice,
      'discountPercent': discount,
      'reportHours': _reportHoursC.text.trim(),
      'preparation': _preparationC.text.trim(),
      'includes': includes,
      'imageUrl': _imageUrl ?? '',
      'isAvailable': _isAvailable,
      'isPopular': _isPopular,
      'isHomeCollection': _isHomeCollection,
      'category': _category,
    };

    try {
      if (widget.existing != null) {
        await getIt<LabTestRepository>().updateLabTest(
          widget.existing!.id,
          data,
        );
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await getIt<LabTestRepository>().addLabTest(data);
      }
      if (mounted) {
        AppToast.show(
          context,
          'Lab test saved successfully',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to save: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: HealMealAppBar(
        title: isEdit ? 'Edit Lab Test' : 'Add Lab Test',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Text('Lab Test Image', style: AppTextStyles.labelLarge),
              SizedBox(height: 8.h),
              _LabTestImagePicker(
                imageUrl: _imageUrl,
                targetTestId: _targetTestId,
                onImagePicked: (url) => setState(() => _imageUrl = url),
              ),
              SizedBox(height: 20.h),

              // Test Name
              HealMealTextField(
                controller: _nameC,
                label: 'Test Name',
                validator: AppValidators.required,
              ),
              SizedBox(height: 12.h),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _labCategories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _category = val ?? 'General'),
              ),
              SizedBox(height: 12.h),

              // Pricing Row
              Row(
                children: [
                  Expanded(
                    child: HealMealTextField(
                      controller: _mrpC,
                      label: 'MRP (Tk)',
                      keyboardType: TextInputType.number,
                      validator: AppValidators.required,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: HealMealTextField(
                      controller: _salePriceC,
                      label: 'Sale Price (Tk)',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final sale = double.tryParse(val) ?? 0;
                        final mrp = double.tryParse(_mrpC.text) ?? 0;
                        if (sale > mrp) return 'Must be <= MRP';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Report Delivery Time
              HealMealTextField(
                controller: _reportHoursC,
                label: 'Report Delivery Time (e.g. 4-6 hours)',
                validator: AppValidators.required,
              ),
              SizedBox(height: 12.h),

              // Preparation Instructions
              HealMealTextField(
                controller: _preparationC,
                label: 'Sample Preparation Instructions',
                maxLines: 3,
              ),
              SizedBox(height: 12.h),

              // What's Included
              HealMealTextField(
                controller: _includesC,
                label: "What's Included (comma-separated)",
                hint: 'e.g. Fasting Blood Sugar, HbA1c, Lipid Profile',
                maxLines: 3,
              ),
              SizedBox(height: 20.h),

              // Toggles
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Available for Booking'),
                      subtitle: Text('Patients can book this test'),
                      value: _isAvailable,
                      onChanged: (v) => setState(() => _isAvailable = v),
                      activeColor: AppColors.primary,
                    ),
                    SizedBox(height: 1),
                    SwitchListTile(
                      title: Text('Mark as Popular'),
                      subtitle: Text('Show in popular tests section'),
                      value: _isPopular,
                      onChanged: (v) => setState(() => _isPopular = v),
                      activeColor: AppColors.accentGold,
                    ),
                    SizedBox(height: 1),
                    SwitchListTile(
                      title: Text('Home Collection Available'),
                      subtitle: Text('Technician visits patient home'),
                      value: _isHomeCollection,
                      onChanged: (v) => setState(() => _isHomeCollection = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
              HealMealButton(
                label: isEdit ? 'Update Lab Test' : 'Create Lab Test',
                size: ButtonSize.large,
                isLoading: _saving,
                onPressed: _save,
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Image Picker Widget -------------------------------------------------------

class _LabTestImagePicker extends StatelessWidget {
  const _LabTestImagePicker({
    this.imageUrl,
    required this.targetTestId,
    required this.onImagePicked,
  });
  final String? imageUrl;
  final String targetTestId;
  final Function(String) onImagePicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final b64 = await ImageUploadUtil.pickImageAsBase64();
        if (b64 != null && b64 != 'TOO_LARGE') {
          onImagePicked(b64);
        } else if (b64 == 'TOO_LARGE') {
          if (context.mounted) {
            AppToast.show(
              context,
              'Image is too large.',
              type: ToastType.error,
            );
          }
        }
      },
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.08),
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: imageUrl == null || imageUrl!.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40.w,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Tap to upload test image',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Max 900KB, JPEG recommended',
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: context.colorTextSecondary,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.lg,
                    child: HealMealImage(imageUrl: imageUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14.w, color: Colors.white),
                          SizedBox(width: 4.w),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
