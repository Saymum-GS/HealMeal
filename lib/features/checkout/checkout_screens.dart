import '../../core/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config.dart';
import '../../core/localization.dart';
import '../../core/widgets.dart';
import '../checkout/checkout_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils.dart';
import '../../core/models.dart';
import '../cart/cart_cubit.dart';
import '../orders/orders_cubit.dart';
import '../../core/services.dart';
import '../../features/account/account_screens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutAddressStep extends StatelessWidget {
  const CheckoutAddressStep({
    super.key,
    required this.onNext,
    required this.addresses,
  });

  final VoidCallback onNext;
  final List<Address> addresses;

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutCubit>();

    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.strings.selectDeliveryAddress,
              style: AppTextStyles.h2,
            ),
            TextButton.icon(
              icon: Icon(Icons.add, size: 20.w),
              label: Text('Add'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: AddEditAddressScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        if (addresses.isEmpty)
          EmptyStateWidget(
            type: EmptyStateType.address,
            onAction: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: AddEditAddressScreen(),
                  ),
                ),
              );
            },
            actionLabel: 'Add Address',
          )
        else
          ...addresses.map((address) {
            final bool isSelected =
                checkout.state.selectedAddressId == address.id;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              child: InkWell(
                onTap: () => checkout.selectAddress(address.id),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : context.colorBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.12),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.04),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : context.colorSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : context.colorBorder,
                          ),
                        ),
                        child: Icon(
                          address.label.toLowerCase() == 'home'
                              ? Icons.home_rounded
                              : Icons.work_rounded,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(address.label, style: AppTextStyles.h3),
                                if (address.isDefault) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${address.houseFlat}, ${address.roadStreet}, ${address.area}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class CheckoutSlotStep extends StatelessWidget {
  const CheckoutSlotStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CheckoutCubit>();

    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(context.strings.deliverySpeed, style: AppTextStyles.h2),
        SizedBox(height: AppSpacing.md),

        Row(
          children: [
            Expanded(
              child: _DeliveryCard(
                title: context.strings.express,
                subtitle: 'Within 2 hours',
                icon: Icons.flash_on_rounded,
                isSelected: cubit.state.deliveryType == 'express',
                onTap: () {
                  cubit.selectDeliveryType('express');
                  onNext();
                },
                gradient: AppColors.primaryGradient as LinearGradient,
                iconColor: Colors.white,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _DeliveryCard(
                title: context.strings.standard,
                subtitle: 'Tomorrow morning',
                icon: Icons.local_shipping_rounded,
                isSelected: cubit.state.deliveryType == 'standard',
                onTap: () {
                  cubit.selectDeliveryType('standard');
                  onNext();
                },
                gradient: AppColors.primaryGradient as LinearGradient,
                iconColor: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Delivery Time Slot', style: AppTextStyles.h3),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Morning 9-12', 'Afternoon 12-5', 'Evening 5-9'].map((
            slot,
          ) {
            final isSelected = cubit.state.selectedTimeSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  cubit.selectTimeSlot(slot);
                }
              },
              selectedColor: AppColors.primaryLight,
              backgroundColor: Theme.of(context).cardColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : context.colorTextSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : context.colorBorder,
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppSpacing.xl),
        InfoBanner(
          title: context.strings.freeDelivery,
          body: context.strings.freeDeliveryRequirement,
          type: InfoBannerType.success,
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: isSelected,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : context.colorSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : context.colorBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: isSelected ? gradient : null,
                    color: isSelected ? null : Colors.white,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: context.colorBorder),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : context.colorTextSecondary,
                    size: 24.w,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : context.colorTextSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutPaymentStep extends StatelessWidget {
  const CheckoutPaymentStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CheckoutCubit>();
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(context.strings.selectPaymentMethod, style: AppTextStyles.h2),
        SizedBox(height: AppSpacing.md),
        ...PaymentMethod.values.map((method) {
          final bool isSelected = cubit.state.selectedPaymentMethod == method;

          Color getIconColor() {
            if (method == PaymentMethod.cod) return Colors.green;
            if (method == PaymentMethod.bkash) return Color(0xFFE2136E);
            return Colors.blue;
          }

          return Semantics(
            button: true,
            checked: isSelected,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              child: InkWell(
                onTap: () {
                  cubit.selectPayment(method);
                  onNext();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : context.colorBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.04),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? getIconColor().withOpacity(0.1)
                              : context.colorSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          method == PaymentMethod.cod
                              ? Icons.payments_rounded
                              : (method == PaymentMethod.bkash
                                    ? Icons.account_balance_wallet_rounded
                                    : Icons.credit_card_rounded),
                          color: isSelected
                              ? getIconColor()
                              : context.colorTextSecondary,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method == PaymentMethod.cod
                                  ? method.label
                                  : '${method.label} (Manual confirmation)',
                              style: AppTextStyles.h3,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              method == PaymentMethod.cod
                                  ? context.strings.codDescription
                                  : 'Our team will call you to manually verify the digital payment transfer.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 28.w,
                        )
                      else
                        Icon(
                          Icons.circle_outlined,
                          color: context.colorBorder,
                          size: 28.w,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class CheckoutReviewStep extends StatelessWidget {
  const CheckoutReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>();
    final checkout = context.watch<CheckoutCubit>().state;
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(context.strings.orderReview, style: AppTextStyles.h2),
        SizedBox(height: AppSpacing.md),

        // Address & Payment Summary
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
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
          child: Column(
            children: <Widget>[
              StreamBuilder<List<Address>>(
                stream: getIt<AddressRepository>().getUserAddresses(
                  AppSession.userId ?? '',
                ),
                builder: (context, snapshot) {
                  final addresses = snapshot.data ?? [];
                  final address = addresses.firstWhere(
                    (a) => a.id == checkout.selectedAddressId,
                    orElse: () => addresses.isNotEmpty
                        ? addresses.first
                        : Address(
                            id: '',
                            label: '',
                            recipientName: '',
                            phoneNumber: '',
                            district: '',
                            upazila: '',
                            area: '',
                            houseFlat: '',
                            roadStreet: '',
                            landmark: '',
                          ),
                  );
                  return ReviewDetailRow(
                    icon: Icons.location_on_rounded,
                    title: context.strings.deliveryAddress,
                    value: address.id.isEmpty
                        ? 'No Address Selected'
                        : address.fullAddress,
                  );
                },
              ),
              SizedBox(height: 32.h),
              ReviewDetailRow(
                icon: Icons.payment_rounded,
                title: context.strings.paymentMethod,
                value: checkout.selectedPaymentMethod.label,
              ),
              SizedBox(height: 32.h),
              ReviewDetailRow(
                icon: Icons.local_shipping_rounded,
                title: context.strings.deliverySpeed,
                value:
                    '${checkout.deliveryType.toUpperCase()} (${checkout.selectedTimeSlot})',
              ),
            ],
          ),
        ),

        SizedBox(height: AppSpacing.lg),
        Text('Items in Order', style: AppTextStyles.labelLarge),
        SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
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
          child: Column(
            children: cart.state.items
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 12.0.h),
                    child: Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: context.colorSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: HealMealImage(
                              imageUrl: item.product.imageUrl,
                              productId: item.product.id,
                              hasImage: item.product.hasImage,
                              label: item.product.drugName,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.drugName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelMedium,
                              ),
                              Text(
                                '${item.quantity} x ${AppFormatters.taka(item.product.effectivePrice)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.colorTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.taka(item.subtotal),
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        SizedBox(height: AppSpacing.lg),
        Text(context.strings.billDetails, style: AppTextStyles.labelLarge),
        SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<Address>>(
          stream: getIt<AddressRepository>().getUserAddresses(
            AppSession.userId ?? '',
          ),
          builder: (context, snapshot) {
            final addresses = snapshot.data ?? [];
            final address = addresses.firstWhere(
              (a) => a.id == checkout.selectedAddressId,
              orElse: () => addresses.isNotEmpty
                  ? addresses.first
                  : Address(
                      id: '',
                      label: '',
                      recipientName: '',
                      phoneNumber: '',
                      district: '',
                      upazila: '',
                      area: '',
                      houseFlat: '',
                      roadStreet: '',
                      landmark: '',
                    ),
            );
            return PriceSummaryCard(
              subtotal: cart.subtotal,
              discount: cart.discountAmount,
              deliveryCharge: cart.deliveryChargeForAddress(address),
              tax: cart.taxAmount,
              cashbackUsed: cart.cashbackUsed,
              total: cart.totalPriceForAddress(address),
            );
          },
        ),
        SizedBox(height: AppSpacing.xl),
        InfoBanner(
          title: context.strings.securePayment,
          body: context.strings.securePaymentDescription,
          type: InfoBannerType.info,
        ),
      ],
    );
  }
}

class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    this.tax = 0.0,
    this.cashbackUsed = 0.0,
    required this.total,
  });

  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double tax;
  final double cashbackUsed;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                SummaryRow(
                  label: context.strings.subtotal,
                  value: AppFormatters.taka(subtotal),
                ),
                SizedBox(height: 12.h),
                SummaryRow(
                  label: context.strings.discount,
                  value: '-${AppFormatters.taka(discount)}',
                  valueColor: AppColors.success,
                ),
                SizedBox(height: 12.h),
                SummaryRow(
                  label: context.strings.deliveryCharge,
                  value: deliveryCharge == 0
                      ? context.strings.free
                      : AppFormatters.taka(deliveryCharge),
                  valueColor: deliveryCharge == 0 ? AppColors.success : null,
                ),
                if (tax > 0) ...[
                  SizedBox(height: 12.h),
                  SummaryRow(
                    label: 'Tax',
                    value: AppFormatters.taka(tax),
                  ),
                ],
                if (cashbackUsed > 0) ...[
                  SizedBox(height: 12.h),
                  SummaryRow(
                    label: 'Cashback Used',
                    value: '-${AppFormatters.taka(cashbackUsed)}',
                    valueColor: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: SummaryRow(
              label: context.strings.totalPayable,
              value: AppFormatters.taka(total),
              emphasize: true,
              valueColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? AppTextStyles.h2
                : AppTextStyles.bodyMedium.copyWith(
                    color: context.colorTextSecondary,
                  ),
          ),
        ),
        Text(
          value,
          style: (emphasize ? AppTextStyles.h2 : AppTextStyles.bodyLarge)
              .copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class ReviewDetailRow extends StatelessWidget {
  const ReviewDetailRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: AppColors.primary, size: 20.w),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colorTextSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CheckoutStepper extends StatelessWidget {
  final int currentStep;

  const CheckoutStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Cart', 'Address', 'Shipping', 'Payment', 'Review', 'Done'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index <= currentStep;
          final isDone = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.white,
                          shape: BoxShape.circle,
                          border: isActive
                              ? null
                              : Border.all(
                                  color: context.colorBorder,
                                  width: 2,
                                ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isDone
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 16.w,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isActive
                                        ? Colors.white
                                        : context.colorTextSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        steps[index],
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 12.sp,
                          color: isActive
                              ? AppColors.primary
                              : context.colorTextSecondary,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: 3.h,
                      margin: EdgeInsets.only(bottom: 24.h),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : context.colorBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _handleContinue() async {
    final checkoutState = context.read<CheckoutCubit>().state;
    final cartCubit = context.read<CartCubit>();

    if (_currentStep < 4) {
      if (_currentStep == 1 && checkoutState.selectedAddressId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a delivery address')),
        );
        return;
      }
      _nextStep();
    } else {
      // Final place order logic
      final userId = AppSession.userId;
      if (userId == null) return;

      setState(() => _isLoading = true);

      try {
        final addressesSnap = await getIt<AddressRepository>()
            .getUserAddresses(userId)
            .first;
        if (addressesSnap.isEmpty) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please add a delivery address')),
            );
          }
          return;
        }

        final selectedAddress = addressesSnap.firstWhere(
          (a) => a.id == checkoutState.selectedAddressId,
          orElse: () => addressesSnap.first,
        );

        // 1. Place order in Firestore securely FIRST
        if (!mounted) return;
        await context.read<OrdersCubit>().placeOrder(
          cartState: cartCubit.state,
          checkoutState: checkoutState,
          deliveryAddress: selectedAddress,
        );

        // 2. Now that the order is safely locked in the DB, process digital payment
        if (checkoutState.selectedPaymentMethod != PaymentMethod.cod) {
          final success = await _showPaymentProcessing(
            checkoutState.selectedPaymentMethod,
          );
          if (!success) {
            if (mounted) {
              setState(() => _isLoading = false);
              cartCubit.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment failed or cancelled. Order saved as Pending.')),
              );
              // Navigate to orders page so they can retry payment later
              context.go('/orders');
            }
            return;
          }
        }

        if (mounted) {
          setState(() => _isLoading = false);
          cartCubit.clearCart();
          context.go('/order-confirmed');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
        }
      }
    }
  }

  Future<bool> _showPaymentProcessing(PaymentMethod method) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _PaymentProcessingDialog(method: method),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(
        title: context.strings.checkout,
        showBack: true,
        onBack: _previousStep,
      ),
      body: Column(
        children: [
          CheckoutStepper(currentStep: _currentStep),
          Expanded(
            child: StreamBuilder<List<Address>>(
              stream: getIt<AddressRepository>().getUserAddresses(
                AppSession.userId ?? '',
              ),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];

                if (addresses.isNotEmpty) {
                  final checkout = context.read<CheckoutCubit>();
                  final selectedId = checkout.state.selectedAddressId;
                  final addressExists = addresses.any(
                    (a) => a.id == selectedId,
                  );
                  if (!addressExists) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        final defaultAddress = addresses.firstWhere(
                          (a) => a.isDefault,
                          orElse: () => addresses.first,
                        );
                        checkout.selectAddress(defaultAddress.id);
                      }
                    });
                  }
                }

                return PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    CheckoutAddressStep(
                      onNext: _nextStep,
                      addresses: addresses,
                    ),
                    CheckoutSlotStep(onNext: _nextStep),
                    CheckoutPaymentStep(onNext: _nextStep),
                    CheckoutReviewStep(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentStep == 4) ...[
                const _MiniCartSummary(),
                SizedBox(height: AppSpacing.md),
                // Prescription Information Notice (Option A: Never Block Checkout)
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    if (state.requiresPrescription &&
                        !state.hasAttachedPrescription) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.assignment_turned_in_outlined,
                                  color: AppColors.primary,
                                  size: 20.w,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    context.tr('Prescription Information', 'প্রেসক্রিপশন তথ্য'),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              context.tr(
                                "Some medicines require a doctor's prescription. You can upload one now or simply place your order and share your prescription photo later via WhatsApp or consultation.",
                                "কিছু ওষুধের জন্য ডাক্তারের প্রেসক্রিপশন প্রয়োজন। আপনি চাইলে এখনই আপলোড করতে পারেন অথবা অর্ডার সাবমিট করে পরে হোয়াটসঅ্যাপে পাঠাতে পারেন।",
                              ),
                              style: AppTextStyles.bodyXSmall.copyWith(
                                color: context.colorTextSecondary,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            HealMealButton(
                              label: context.tr('Upload Prescription (Optional)', 'প্রেসক্রিপশন আপলোড (ঐচ্ছিক)'),
                              type: ButtonType.outlined,
                              onPressed: () async {
                                final result = await context.push<String>(
                                  '/prescriptions/upload',
                                );
                                if (result != null &&
                                    result.isNotEmpty &&
                                    context.mounted) {
                                  context
                                      .read<CartCubit>()
                                      .setPrescriptionStatus(
                                        true,
                                        prescriptionId: result,
                                      );
                                }
                              },
                              size: ButtonSize.small,
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
              HealMealButton(
                label: _currentStep == 4 ? context.tr('Submit Order', 'অর্ডার সাবমিট করুন') : context.tr('Continue', 'পরবর্তী ধাপ'),
                size: ButtonSize.large,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentProcessingDialog extends StatefulWidget {
  final PaymentMethod method;
  const _PaymentProcessingDialog({required this.method});

  @override
  State<_PaymentProcessingDialog> createState() =>
      _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<_PaymentProcessingDialog> {
  String _status = 'Connecting to Secure Gateway...';
  double _progress = 0.2;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() async {
    await Future.delayed(Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _status = 'Authorizing Transaction...';
      _progress = 0.6;
    });

    await Future.delayed(Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _status = 'Finalizing Payment...';
      _progress = 0.9;
    });

    await Future.delayed(Duration(milliseconds: 1000));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80.w,
              height: 80.h,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.subtle,
                    color: AppColors.primary,
                  ),
                  Center(
                    child: Icon(
                      widget.method == PaymentMethod.bkash
                          ? Icons.account_balance_wallet_rounded
                          : Icons.credit_card_rounded,
                      color: AppColors.primary,
                      size: 32.w,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Processing Payment',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              _status,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Text(
              'Please do not close the app or press back.',
              style: AppTextStyles.bodyXSmall.copyWith(
                color: context.colorTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Container(
                width: 140.w,
                height: 140.h,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 80.w,
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
              ),
              SizedBox(height: 48.h),
              Text(
                'Order Placed Successfully!',
                style: AppTextStyles.h1.copyWith(fontSize: 28.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Your order has been received and is being processed. You will receive a confirmation call shortly.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.colorTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              Spacer(),
              HealMealButton(
                label: 'Track My Order',
                onPressed: () => context.go('/orders'),
                size: ButtonSize.large,
              ),
              SizedBox(height: 16.h),
              HealMealButton(
                label: 'Back to Home',
                onPressed: () => context.go('/home'),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                size: ButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCartSummary extends StatelessWidget {
  const _MiniCartSummary();

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.watch<CartCubit>();
    final checkoutState = context.watch<CheckoutCubit>().state;

    return StreamBuilder<List<Address>>(
      stream: getIt<AddressRepository>().getUserAddresses(
        AppSession.userId ?? '',
      ),
      builder: (context, snapshot) {
        final addresses = snapshot.data ?? [];
        final address = addresses.firstWhere(
          (a) => a.id == checkoutState.selectedAddressId,
          orElse: () => addresses.isNotEmpty
              ? addresses.first
              : Address(
                  id: '',
                  label: '',
                  recipientName: '',
                  phoneNumber: '',
                  district: '',
                  upazila: '',
                  area: '',
                  houseFlat: '',
                  roadStreet: '',
                  landmark: '',
                ),
        );

        final double subtotal = cartCubit.subtotal;
        final double deliveryCharge = cartCubit.deliveryChargeForAddress(address);
        final double total = cartCubit.totalPriceForAddress(address);

        return Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colorBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: AppTextStyles.bodyMedium),
                  Text(
                    '৳${subtotal.toStringAsFixed(2)}',
                    style: AppTextStyles.h3,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery', style: AppTextStyles.bodyMedium),
                  Text(
                    deliveryCharge == 0
                        ? 'FREE'
                        : '৳${deliveryCharge.toStringAsFixed(2)}',
                    style: AppTextStyles.h3.copyWith(
                      color: deliveryCharge == 0 ? AppColors.success : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.h3),
                  Text(
                    '৳${total.toStringAsFixed(2)}',
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
