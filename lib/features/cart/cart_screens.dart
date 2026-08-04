import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_cubit.dart';

import '../../core/config.dart';

import '../../core/localization.dart';
import '../../core/widgets.dart';
import '../../core/utils.dart';
import '../checkout/checkout_screens.dart';
import 'cart_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (BuildContext context, CartState state) {
        final isEmpty = state.items.isEmpty;

        return Scaffold(
          backgroundColor: context.colorSurface,
          appBar: HealMealAppBar(
            title:
                '${context.strings.myCart} (${context.read<CartCubit>().totalCount})',
            showBack: true,
          ),
          body: isEmpty
              ? EmptyStateWidget(
                  type: EmptyStateType.cart,
                  onAction: () => context.go('/home'),
                  actionLabel: context.strings.startShopping,
                )
              : AppLayout.constrained(
                  context: context,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: <Widget>[
                      CheckoutStepper(currentStep: 0),
                      SizedBox(height: 8.h),
                      if (state.items.any(
                        (item) => item.product.requiresPrescription,
                      )) ...<Widget>[
                        InfoBanner(
                          title: context.strings.rxRequired,
                          body:
                              'You can upload your prescription now or share it after placing your order.',
                          type: InfoBannerType.info,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              if (context.read<AuthCubit>().state
                                  is AuthUnauthenticated) {
                                showGuestAccountSheet(
                                  context,
                                  customMessage:
                                      'Sign in to upload your prescription.',
                                );
                                return;
                              }
                              final result = await context.push<String>(
                                '/prescriptions/upload',
                              );
                              if (result != null &&
                                  result.isNotEmpty &&
                                  context.mounted) {
                                context.read<CartCubit>().setPrescriptionStatus(
                                  true,
                                  prescriptionId: result,
                                );
                              }
                            },
                            child: Text(context.strings.uploadPrescription),
                          ),
                        ),
                        SizedBox(height: 6.h),
                      ],
                      ...state.items.map((item) => _CartItemCard(item: item)),
                      SizedBox(height: 8.h),
                      const _CouponCard(),
                      SizedBox(height: 16.h),
                      PriceSummaryCard(
                        subtotal: context.read<CartCubit>().subtotal,
                        discount: context.read<CartCubit>().discountAmount,
                        deliveryCharge: context
                            .read<CartCubit>()
                            .deliveryCharge,
                        tax: context.read<CartCubit>().taxAmount,
                        cashbackUsed: context.read<CartCubit>().cashbackUsed,
                        total: context.read<CartCubit>().totalPrice,
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child:
                        context.watch<AuthCubit>().state is AuthUnauthenticated
                        ? Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.1),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Create a free account to save your cart, track delivery, and get exclusive offers.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primaryDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                HealMealButton(
                                  label: 'Create Account',
                                  onPressed: () => context.push('/register'),
                                  size: ButtonSize.large,
                                ),
                                SizedBox(height: 8.h),
                                TextButton(
                                  onPressed: () => context.push('/login'),
                                  child: Text(
                                    'Already have an account? Sign In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : HealMealButton(
                            label: 'Proceed to Checkout',
                            size: ButtonSize.large,
                            onPressed: () {
                              final CartState cartState = context
                                  .read<CartCubit>()
                                  .state;
                              final bool hasRx = cartState.items.any(
                                (item) => item.product.requiresPrescription,
                              );
                              if (hasRx && !cartState.hasAttachedPrescription) {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(context.strings.rxRequired),
                                    content: Text(
                                      'Please upload and approve a prescription before ordering.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              context.push('/checkout');
                            },
                          ),
                  ),
                ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});
  final CartEntry item;

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.white, size: 28.w),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => ConfirmDialog(
                title: 'Remove item',
                body: 'Remove ${item.product.drugName} from your cart?',
                confirmLabel: 'Remove',
                isDangerous: true,
              ),
            ) ??
            false;
      },
      onDismissed: (_) => cartCubit.removeItem(item.product.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Image with soft background
            Container(
              decoration: BoxDecoration(
                color: context.colorSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(8),
              child: HealMealImage(
                imageUrl: item.product.imageUrl,
                productId: item.product.id,
                hasImage: item.product.hasImage,
                label: item.product.drugName,
                width: 70.w,
                height: 70.h,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.product.drugName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(height: 1.2),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.product.manufacturer,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colorTextSecondary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      PriceDisplay(
                        mrp: item.product.mrp,
                        salePrice: item.product.effectivePrice,
                        size: PriceDisplaySize.small,
                      ),
                      Spacer(),
                      // Sleek Quantity Control
                      Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: () => cartCubit.updateQuantity(
                                item.product.id,
                                item.quantity - 1,
                              ),
                              icon: Icon(Icons.remove_rounded, size: 20.w),
                              constraints: BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                              color: AppColors.primary,
                            ),
                            InkWell(
                              onTap: () => showQuantitySelectorSheet(
                                context,
                                productName: item.product.drugName,
                                initialQuantity: item.quantity,
                                maxStock: item.product.countInStock,
                                onQuantitySelected: (newQty) {
                                  cartCubit.updateQuantity(
                                    item.product.id,
                                    newQty,
                                  );
                                },
                              ),
                              borderRadius: AppRadius.sm,
                              child: Container(
                                constraints: BoxConstraints(minWidth: 32),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.quantity}',
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => cartCubit.updateQuantity(
                                item.product.id,
                                item.quantity + 1,
                              ),
                              icon: Icon(
                                Icons.add_rounded,
                                size: 20.w,
                                color: AppColors.primary,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard();

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;
    return InkWell(
      onTap: () => _openCouponSheet(context),
      child: DottedBorder(
        color: AppColors.primary,
        borderType: BorderType.RRect,
        radius: Radius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: <Widget>[
              Icon(Icons.sell_rounded, color: AppColors.primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cartState.couponCode == null
                          ? 'Add Coupon Code'
                          : 'Coupon Applied',
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      cartState.couponCode ??
                          'Use SAVE20, NEWUSER50, or REFILL10',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colorTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (cartState.couponCode != null)
                IconButton(
                  onPressed: () => context.read<CartCubit>().removeCoupon(),
                  icon: Icon(Icons.close_rounded, size: 18.w),
                )
              else
                Icon(Icons.arrow_forward_ios_rounded, size: 16.w),
            ],
          ),
        ),
      ),
    );
  }

  void _openCouponSheet(BuildContext context) {
    final controller = TextEditingController(
      text: context.read<CartCubit>().state.couponCode,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Apply coupon', style: AppTextStyles.h2),
            SizedBox(height: 12.h),
            HealMealTextField(controller: controller, label: 'Coupon code'),
            SizedBox(height: 16.h),
            HealMealButton(
              label: context.strings.applyCoupon,
              onPressed: () async {
                final code = controller.text;
                Navigator.of(ctx).pop(); // dismiss sheet first
                try {
                  await context.read<CartCubit>().applyCoupon(code);
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      'Coupon applied successfully',
                      type: ToastType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      'Failed to apply coupon: ${e.toString().replaceAll('Exception: ', '')}',
                      type: ToastType.error,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
