import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/utils.dart';
import '../../../../core/widgets.dart';
import '../admin_cubit.dart';
import 'components.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<OrderStatus?> _statuses = [
    null, // All
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.dispatched,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<AdminOrderCubit>().fetchOrders(
          refresh: true,
          status: _statuses[_tabController.index],
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderCubit>().fetchOrders(refresh: true, status: null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStatusUpdateDialog(BuildContext context, AppOrder order) {
    final cubit = context.read<AdminOrderCubit>();
    showDialog(
      context: context,
      builder: (context) {
        return BlocProvider.value(
          value: cubit,
          child: AlertDialog(
            title: Text('Update Order Status', style: AppTextStyles.h2),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: OrderStatus.values.map((status) {
                  return RadioListTile<OrderStatus>(
                    title: Text(status.name.toUpperCase()),
                    value: status,
                    groupValue: order.status,
                    onChanged: (val) {
                      if (val != null) {
                        context.read<AdminOrderCubit>().updateOrderStatus(
                          order.id,
                          val,
                        );
                        Navigator.pop(context);
                        AppToast.show(
                          context,
                          'Order updated.',
                          type: ToastType.success,
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              HealMealButton(
                type: ButtonType.text,
                onPressed: () => Navigator.pop(context),
                label: 'Cancel',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdvancedEditDialog(BuildContext context, AppOrder order) {
    final cubit = context.read<AdminOrderCubit>();
    final paymentCtrl = TextEditingController(text: order.paymentStatus);
    final refundCtrl = TextEditingController(text: order.refundStatus);
    final fulfillmentCtrl = TextEditingController(text: order.fulfillmentNotes);
    final deliveryCtrl = TextEditingController(
      text: order.deliveryAssignment ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return BlocProvider.value(
          value: cubit,
          child: AlertDialog(
            title: Text('Advanced Order Details', style: AppTextStyles.h2),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HealMealTextField(
                    controller: paymentCtrl,
                    label: 'Payment Status (e.g. pending, paid)',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  HealMealTextField(
                    controller: refundCtrl,
                    label: 'Refund Status (e.g. none, full, partial)',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  HealMealTextField(
                    controller: fulfillmentCtrl,
                    label: 'Fulfillment Notes',
                    maxLines: 2,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  HealMealTextField(
                    controller: deliveryCtrl,
                    label: 'Delivery Assignment',
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
                onPressed: () {
                  context.read<AdminOrderCubit>().updateAdvancedOrderFields(
                    order.id,
                    paymentCtrl.text,
                    refundCtrl.text,
                    fulfillmentCtrl.text,
                    deliveryCtrl.text.isEmpty ? null : deliveryCtrl.text,
                  );
                  Navigator.pop(context);
                  AppToast.show(
                    context,
                    'Order updated.',
                    type: ToastType.success,
                  );
                },
                label: 'Save',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderDetailSheet(BuildContext context, AppOrder order) {
    final cubit = context.read<AdminOrderCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: AppSpacing.md),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.colorTextMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header with status update button
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Details', style: AppTextStyles.h2),
                            Text(
                              order.formattedCode,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.colorTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAdvancedEditDialog(context, order);
                            },
                            icon: Icon(
                              Icons.settings_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          HealMealButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showStatusUpdateDialog(context, order);
                            },
                            prefixIcon: Icons.edit_rounded,
                            label: order.status.name,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Tamper Warning for newly placed orders
                      if (order.status == OrderStatus.placed) ...[
                        InfoBanner(
                          title: 'Verification Required',
                          body:
                              'Please verify the order items and total amount match the expected medicine prices before confirming.',
                          type: InfoBannerType.warning,
                        ),
                        SizedBox(height: AppSpacing.lg),
                      ],
                      // Customer info
                      _OrderDetailSection(
                        title: 'Customer',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _InfoRow('Name', order.customerName ?? 'N/A'),
                          _InfoRow('Phone', order.customerPhone ?? 'N/A'),
                          _InfoRow(
                            'Order Date',
                            AppFormatters.compactDateTime(order.placedAt),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Delivery address
                      if (order.deliveryAddress != null)
                        _OrderDetailSection(
                          title: 'Delivery Address',
                          icon: Icons.location_on_outlined,
                          children: [
                            _InfoRow(
                              'Address',
                              order.deliveryAddress!.fullAddress,
                            ),
                            _InfoRow(
                              'District',
                              order.deliveryAddress!.district,
                            ),
                          ],
                        ),
                      SizedBox(height: AppSpacing.lg),
                      // Payment info
                      _OrderDetailSection(
                        title: 'Payment',
                        icon: Icons.payment_rounded,
                        children: [
                          _InfoRow(
                            'Method',
                            order.paymentMethod.name.toUpperCase(),
                          ),
                          _InfoRow('Status', order.paymentStatus),
                          if (order.refundStatus != null &&
                              order.refundStatus!.isNotEmpty)
                            _InfoRow('Refund', order.refundStatus!),
                          _InfoRow(
                            'Subtotal',
                            AppFormatters.taka(order.subtotal),
                          ),
                          if (order.discountAmount > 0)
                            _InfoRow(
                              'Discount',
                              '- ${AppFormatters.taka(order.discountAmount)}',
                            ),

                          _InfoRow(
                            'Total',
                            AppFormatters.taka(order.total),
                            isHighlighted: true,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Order items
                      Text(
                        'Items (${order.items.length})',
                        style: AppTextStyles.h3,
                      ),
                      SizedBox(height: AppSpacing.md),
                      ...order.items.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52.w,
                                child: HealMealImage(
                                  imageUrl: item.product.imageUrl,
                                  productId: item.product.id,
                                  hasImage: item.product.hasImage,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.drugName,
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    Text(
                                      'Qty: ${item.quantity} x ${AppFormatters.taka(item.product.effectivePrice)}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppFormatters.taka(item.subtotal),
                                style: AppTextStyles.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (order.specialNote != null &&
                          order.specialNote!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.lg),
                        _OrderDetailSection(
                          title: 'Special Note',
                          icon: Icons.note_outlined,
                          children: [
                            Text(
                              order.specialNote!,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                      if ((order.fulfillmentNotes != null &&
                              order.fulfillmentNotes!.isNotEmpty) ||
                          order.deliveryAssignment != null) ...[
                        SizedBox(height: AppSpacing.lg),
                        _OrderDetailSection(
                          title: 'Operations',
                          icon: Icons.local_shipping_outlined,
                          children: [
                            if (order.fulfillmentNotes != null &&
                                order.fulfillmentNotes!.isNotEmpty)
                              _InfoRow('Notes', order.fulfillmentNotes!),
                            if (order.deliveryAssignment != null)
                              _InfoRow('Delivery', order.deliveryAssignment!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminOrderCubit>().state;
    final orders = state.allOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statuses
              .map((s) => Tab(text: s == null ? 'All' : s.name.toUpperCase()))
              .toList(),
        ),
      ),
      body: state.isLoading && orders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text('No orders found.'))
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length + (state.hasMoreOrders ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == orders.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<AdminOrderCubit>().loadMoreOrders();
                  });
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final order = orders[index];
                return RoleCard(
                  child: InkWell(
                    onTap: () => _showOrderDetailSheet(context, order),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.formattedCode, style: AppTextStyles.labelLarge),
                                SizedBox(height: 2.h),
                                Text(
                                  order.medicineNamesSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  "${order.items.length} items - ${AppFormatters.taka(order.total)}",
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.colorTextSecondary,
                                  ),
                                ),
                                if (order.userId == null) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Unverified Account',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          StatusBadge(status: order.status.name),
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

class _OrderDetailSection extends StatelessWidget {
  const _OrderDetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.w, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.isHighlighted = false});
  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.colorTextSecondary,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isHighlighted
                  ? AppTextStyles.labelLarge.copyWith(color: AppColors.primary)
                  : AppTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
