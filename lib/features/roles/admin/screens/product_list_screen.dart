import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config.dart';
import '../../../../core/widgets.dart';
import '../../../../core/models.dart';
import '../../../../core/utils.dart';
import '../../../../core/repositories.dart';
import '../../../../core/services.dart';

import '../../../products/product_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminProductListScreen extends StatefulWidget {
  final String? categoryId;
  const AdminProductListScreen({super.key, this.categoryId});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      context.read<ProductCubit>().setCategory(widget.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Manage Medicines', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: HealMealTextField(
              hint: 'Search medicines by name...',
              prefix: Icon(Icons.search),
              onChanged: (query) =>
                  context.read<ProductCubit>().filter(query: query),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All'),
                  selected:
                      context.watch<ProductCubit>().state.activeStatus == null,
                  onSelected: (v) =>
                      context.read<ProductCubit>().setLifecycleStatus(null),
                ),
                SizedBox(width: 8.w),
                ...ProductLifecycleStatus.values.map(
                  (status) => Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.name.toUpperCase()),
                      selected:
                          context.watch<ProductCubit>().state.activeStatus ==
                          status,
                      onSelected: (v) => context
                          .read<ProductCubit>()
                          .setLifecycleStatus(v ? status : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state.loading && state.allProducts.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                final products = state.filteredProducts;
                if (products.isEmpty) {
                  return Center(
                    child: Text("No medicines found for this filter."),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  itemCount:
                      products.length +
                      (state.hasMore && state.searchQuery == null ? 1 : 0),
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.read<ProductCubit>().loadMore();
                      });
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0.w),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final product = products[index];
                    final id = product.id;

                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 50.w,
                          child: HealMealImage(
                            imageUrl: product.imageUrl,
                            productId: product.id,
                            hasImage: product.hasImage,
                          ),
                        ),
                        title: Text(product.drugName),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.manufacturer,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            StatusBadge(status: product.lifecycleStatus.name),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push('/admin/products/edit/$id');
                            } else if (value == 'delete') {
                              _deleteProduct(context, product);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20.w),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/products/add'),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Medicine?"),
        content: Text(
          "Are you sure you want to delete ${product.drugName}? This action cannot be undone.",
        ),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => context.pop(false),
            label: 'Cancel',
          ),
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => context.pop(true),
            label: 'Delete',
            foregroundColor: AppColors.error,
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await getIt<ProductRepository>().deleteProduct(product.id);
        if (context.mounted) {
          AppToast.show(
            context,
            'Medicine deleted successfully',
            type: ToastType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(
            context,
            'Error deleting medicine: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }
}
