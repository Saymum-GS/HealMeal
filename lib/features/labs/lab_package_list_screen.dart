import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../core/config.dart';
import '../../core/services.dart';
import '../../core/repositories.dart';
import '../../core/models.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LabPackageListScreen extends StatefulWidget {
  const LabPackageListScreen({super.key});

  @override
  State<LabPackageListScreen> createState() => _LabPackageListScreenState();
}

class _LabPackageListScreenState extends State<LabPackageListScreen> {
  List<LabPackage>? _packages;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await getIt<LabTestRepository>().fetchLabPackages();
    if (mounted) {
      setState(() => _packages = packages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Lab Packages', showBack: true),
      body: _packages == null
          ? Center(child: CircularProgressIndicator())
          : _packages!.isEmpty
          ? Center(child: Text('No packages found'))
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _packages!.length,
              itemBuilder: (context, index) {
                final package = _packages![index];
                if (!package.isActive) return SizedBox.shrink();
                return Card(
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  child: InkWell(
                    onTap: () => context.push('/labs/packages/${package.id}'),
                    borderRadius: AppRadius.md,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: AppColors.subtle,
                              borderRadius: AppRadius.sm,
                            ),
                            child: HealMealImage(
                              imageUrl: package.imageUrl,
                              icon: Icons.science_rounded,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.name,
                                  style: AppTextStyles.labelLarge,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  package.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.colorTextMuted,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Text(
                                      '৳${package.salePrice}',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    if (package.mrp > package.salePrice)
                                      Text(
                                        '৳${package.mrp}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: context.colorTextMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.colorTextMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
