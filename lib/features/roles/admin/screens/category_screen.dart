import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';
import '../../../../core/services.dart';
import '../../../../core/repositories.dart';
import '../admin_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminCategoriesCubit>();
    if (cubit.state is AdminCategoriesInitial) {
      cubit.loadCategories();
    }
    return Scaffold(
      appBar: HealMealAppBar(title: 'Manage Categories', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context),
        icon: Icon(Icons.add_rounded),
        label: Text('Add Category'),
      ),
      body: BlocBuilder<AdminCategoriesCubit, AdminCategoriesState>(
        builder: (context, state) {
          if (state is AdminCategoriesInitial) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is! AdminCategoriesLoaded) {
            return Center(child: Text('Unable to load categories.'));
          }
          final categories = state.categories;
          if (categories.isEmpty) {
            return Center(child: Text('No categories yet. Tap + to add one.'));
          }
          return ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              100,
            ),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              context.read<AdminCategoriesCubit>().reorderCategories(
                oldIndex,
                newIndex,
              );
            },
            itemBuilder: (context, index) {
              final cat = categories[index];
              final id = cat.id;
              final isVisible = cat.isActive;

              return Card(
                key: ValueKey(id),
                child: ListTile(
                  onTap: () => context.push('/admin/products?category=$id'),
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: context.colorTextMuted,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        _getIconData(cat.iconKey),
                        color: AppColors.primary,
                        size: 20.w,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Slug: ${cat.slug}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isVisible,
                        onChanged: (val) {
                          context.read<AdminCategoriesCubit>().toggleVisibility(
                            cat,
                            val,
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showCategoryDialog(context, category: cat);
                          } else if (value == 'delete') {
                            _deleteCategory(context, id);
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
                                SizedBox(width: AppSpacing.sm),
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
                                SizedBox(width: AppSpacing.sm),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
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

  IconData _getIconData(String? name) {
    const map = {
      'medication_rounded': Icons.medication_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'health_and_safety_rounded': Icons.health_and_safety_rounded,
      'monitor_heart_rounded': Icons.monitor_heart_rounded,
      'heart_broken_rounded': Icons.heart_broken_rounded,
      'child_care_rounded': Icons.child_care_rounded,
      'spa_rounded': Icons.spa_rounded,
      'biotech_rounded': Icons.biotech_rounded,
      'local_pharmacy_rounded': Icons.local_pharmacy_rounded,
      'vaccines_rounded': Icons.vaccines_rounded,
      'healing_rounded': Icons.healing_rounded,
      'science_rounded': Icons.science_rounded,
    };
    return map[name] ?? Icons.category_rounded;
  }

  void _showCategoryDialog(BuildContext context, {AppCategory? category}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminCategoriesCubit>(),
        child: _CategoryFormDialog(category: category),
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category?'),
        content: Text(
          'Medicines assigned to this category will become uncategorised. This cannot be undone.',
        ),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(context, false),
            label: 'Cancel',
          ),
          HealMealButton(
            backgroundColor: AppColors.error,
            onPressed: () => Navigator.pop(context, true),
            label: 'Delete',
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await context.read<AdminCategoriesCubit>().deleteCategory(id);
        if (context.mounted) {
          AppToast.show(context, 'Category deleted.', type: ToastType.success);
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, 'Error deleting category: $e', type: ToastType.error);
        }
      }
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final AppCategory? category;
  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController slugController;
  late final TextEditingController iconController;
  late final TextEditingController colorController;
  String? _parentId;
  String? _imageUrl;
  late final String _targetId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.category != null;
    nameController = TextEditingController(text: widget.category?.name ?? '');
    slugController = TextEditingController(
      text: isEdit ? widget.category!.slug : '',
    );
    iconController = TextEditingController(
      text: widget.category?.iconKey ?? 'medication_rounded',
    );
    colorController = TextEditingController(
      text: widget.category?.colorHex ?? '#607D8B',
    );
    _parentId = widget.category?.parentId;
    _imageUrl = widget.category?.imageUrl;
    _targetId =
        widget.category?.id ??
        FirebaseFirestore.instance.collection('categories').doc().id;
  }

  @override
  void dispose() {
    nameController.dispose();
    slugController.dispose();
    iconController.dispose();
    colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final cubitState = context.read<AdminCategoriesCubit>().state;
    List<AppCategory> allCats = [];
    if (cubitState is AdminCategoriesLoaded) {
      allCats = cubitState.categories
          .where((c) => c.id != widget.category?.id)
          .toList();
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit Category' : 'Add Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final b64 = await ImageUploadUtil.pickImageAsBase64();
                if (b64 != null && b64 != 'TOO_LARGE') {
                  setState(() => _imageUrl = b64);
                } else if (b64 == 'TOO_LARGE') {
                  if (!context.mounted) return;
                  AppToast.show(
                    context,
                    'Image is too large.',
                    type: ToastType.error,
                  );
                }
              },
              child: Container(
                height: 120.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colorSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorBorder),
                ),
                child: _imageUrl == null || _imageUrl!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 32.w),
                            SizedBox(height: 4.h),
                            Text('Upload Category Image'),
                          ],
                        ),
                      )
                    : HealMealImage(imageUrl: _imageUrl, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            HealMealTextField(
              controller: nameController,
              label: 'Display Name (English)',
              hint: 'e.g. Pain Relief',
            ),
            SizedBox(height: AppSpacing.md),
            HealMealTextField(
              controller: slugController,
              label: 'Slug / ID',
              hint: 'e.g. pain-relief',
              readOnly: isEdit,
            ),
            if (isEdit)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Slug cannot be changed after creation.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colorTextMuted,
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.md),
            if (allCats.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _parentId,
                decoration: InputDecoration(
                  labelText: 'Parent Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None (Root Category)'),
                  ),
                  ...allCats.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (val) => setState(() => _parentId = val),
              ),
              SizedBox(height: AppSpacing.md),
            ],
            HealMealTextField(
              controller: colorController,
              label: 'Color Hex (e.g. #4CAF50)',
            ),
            SizedBox(height: AppSpacing.md),
            HealMealTextField(
              controller: iconController,
              label: 'Icon Name',
              hint: 'e.g. medication_rounded',
            ),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children:
                  [
                        'medication_rounded',
                        'favorite_rounded',
                        'health_and_safety_rounded',
                        'biotech_rounded',
                        'vaccines_rounded',
                        'healing_rounded',
                        'spa_rounded',
                        'child_care_rounded',
                        'science_rounded',
                      ]
                      .map(
                        (name) => ActionChip(
                          label: Text(name, style: TextStyle(fontSize: 10.sp)),
                          onPressed: () => iconController.text = name,
                        ),
                      )
                      .toList(),
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
          onPressed: _isLoading
              ? null
              : () async {
                  final name = nameController.text.trim();
                  final slug = slugController.text.trim();
                  final icon = iconController.text.trim().isNotEmpty
                      ? iconController.text.trim()
                      : 'medication_rounded';
                  final color = colorController.text.trim();

                  if (name.isEmpty || slug.isEmpty) {
                    AppToast.show(
                      context,
                      'Name and Slug are required.',
                      type: ToastType.error,
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  final newCat = AppCategory(
                    id: isEdit ? widget.category!.id : _targetId,
                    name: name,
                    slug: slug,
                    iconKey: icon,
                    colorHex: color,
                    imageUrl: _imageUrl ?? '',
                    parentId: _parentId,
                    sortOrder: isEdit ? widget.category!.sortOrder : 999,
                    isActive: isEdit ? widget.category!.isActive : true,
                  );

                  try {
                    if (isEdit) {
                      await context
                          .read<AdminCategoriesCubit>()
                          .updateCategory(newCat);
                    } else {
                      final repo = getIt<CategoryRepository>();
                      await repo.saveCategory(newCat);
                      if (context.mounted) {
                        context.read<AdminCategoriesCubit>().loadCategories();
                      }
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        isEdit ? 'Category updated.' : 'Category created.',
                        type: ToastType.success,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.show(context, 'Failed to save: $e', type: ToastType.error);
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          isLoading: _isLoading,
          label: isEdit ? 'Update' : 'Create',
        ),
      ],
    );
  }
}
