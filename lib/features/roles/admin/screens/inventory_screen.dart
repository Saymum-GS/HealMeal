import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';
import '../cubits/admin_inventory_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminInventoryCubit>().loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: HealMealAppBar(
          title: 'Inventory',
          showBack: true,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Low Stock'),
              Tab(text: 'Out of Stock'),
              Tab(text: 'All Medicines'),
            ],
          ),
        ),
        body: BlocBuilder<AdminInventoryCubit, AdminInventoryState>(
          builder: (context, state) {
            if (state is AdminInventoryLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is AdminInventoryError) {
              return Center(
                child: EmptyStateWidget(
                  type: EmptyStateType.error,
                  customBody: state.message,
                  actionLabel: 'Retry',
                  onAction: () =>
                      context.read<AdminInventoryCubit>().loadInventory(),
                ),
              );
            }
            if (state is AdminInventoryLoaded) {
              return TabBarView(
                children: [
                  _ProductList(
                    products: state.lowStockProducts,
                    emptyMessage: 'No low stock medicines.',
                  ),
                  _ProductList(
                    products: state.outOfStockProducts,
                    emptyMessage: 'No out of stock medicines.',
                  ),
                  _AllProductsTab(
                    products: state.allProducts,
                    isSearching: state.isSearching,
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final String emptyMessage;

  const _ProductList({required this.products, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return EmptyStateWidget(
        type: EmptyStateType.search,
        customTitle: 'Nothing here yet',
        customBody: emptyMessage,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: products.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(product.drugName),
            subtitle: Text('Stock: ${product.countInStock} units'),
            trailing: IconButton.filledTonal(
              icon: Icon(Icons.edit_rounded, size: 20.w),
              onPressed: () => _showEditStockDialog(context, product),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AllProductsTab extends StatefulWidget {
  final List<Product> products;
  final bool isSearching;
  const _AllProductsTab({required this.products, this.isSearching = false});

  @override
  State<_AllProductsTab> createState() => _AllProductsTabState();
}

class _AllProductsTabState extends State<_AllProductsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: HealMealTextField(
            label: 'Search Medicines',
            prefix: Icon(Icons.search),
            onChanged: (v) {
              setState(() => _searchQuery = v);
              context.read<AdminInventoryCubit>().searchAllProducts(
                _searchQuery,
              );
            },
          ),
        ),
        Expanded(
          child: widget.isSearching
              ? const Center(child: CircularProgressIndicator())
              : _ProductList(
                  products: widget.products,
                  emptyMessage: 'No medicines found.',
                ),
        ),
      ],
    );
  }
}

void _showEditStockDialog(BuildContext context, Product product) {
  final controller = TextEditingController(
    text: product.countInStock.toString(),
  );
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Edit Stock'),
      content: HealMealTextField(
        controller: controller,
        keyboardType: TextInputType.number,
        label: 'Stock Count',
      ),
      actions: [
        HealMealButton(
          type: ButtonType.text,
          onPressed: () => Navigator.pop(ctx),
          label: 'Cancel',
        ),
        HealMealButton(
          onPressed: () async {
            final newCount = int.tryParse(controller.text) ?? 0;
            try {
              await context.read<AdminInventoryCubit>().updateStock(
                product.id,
                newCount,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppToast.show(ctx, 'Stock updated.', type: ToastType.success);
              }
            } catch (e) {
              if (ctx.mounted) {
                AppToast.show(ctx, 'Failed to update stock: $e', type: ToastType.error);
              }
            }
          },
          label: 'Save',
        ),
      ],
    ),
  );
}
