import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'buttons.dart';

Future<void> showQuantitySelectorSheet(
  BuildContext context, {
  required String productName,
  required int initialQuantity,
  int maxStock = 999,
  required ValueChanged<int> onQuantitySelected,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colorSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _QuantitySelectorModalBody(
      productName: productName,
      initialQuantity: initialQuantity <= 0 ? 1 : initialQuantity,
      maxStock: maxStock <= 0 ? 999 : maxStock,
      onQuantitySelected: onQuantitySelected,
    ),
  );
}

class _QuantitySelectorModalBody extends StatefulWidget {
  const _QuantitySelectorModalBody({
    required this.productName,
    required this.initialQuantity,
    required this.maxStock,
    required this.onQuantitySelected,
  });

  final String productName;
  final int initialQuantity;
  final int maxStock;
  final ValueChanged<int> onQuantitySelected;

  @override
  State<_QuantitySelectorModalBody> createState() =>
      _QuantitySelectorModalBodyState();
}

class _QuantitySelectorModalBodyState
    extends State<_QuantitySelectorModalBody> {
  late int _quantity;
  late TextEditingController _controller;

  final List<Map<String, dynamic>> _presets = [
    {'label': '1 Unit', 'value': 1},
    {'label': '5 Units', 'value': 5},
    {'label': '10 (1 Strip)', 'value': 10},
    {'label': '15 Units', 'value': 15},
    {'label': '20 (2 Strips)', 'value': 20},
    {'label': '30 (1 Month)', 'value': 30},
    {'label': '50 Units', 'value': 50},
    {'label': '100 Units', 'value': 100},
  ];

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(1, widget.maxStock);
    _controller = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuantity(int val) {
    final clamped = val.clamp(1, widget.maxStock);
    setState(() {
      _quantity = clamped;
      _controller.text = '$clamped';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: bottomInset + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colorBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Select Quantity',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            widget.productName,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20.h),

          // Custom input row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _quantity > 1 ? () => _setQuantity(_quantity - 1) : null,
                icon: Icon(Icons.remove, size: 20.w),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 16.w),
              SizedBox(
                width: 90.w,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.md,
                      borderSide: BorderSide(color: context.colorBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.md,
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null && parsed > 0) {
                      setState(() => _quantity = parsed.clamp(1, widget.maxStock));
                    }
                  },
                ),
              ),
              SizedBox(width: 16.w),
              IconButton.filledTonal(
                onPressed: _quantity < widget.maxStock
                    ? () => _setQuantity(_quantity + 1)
                    : null,
                icon: Icon(Icons.add, size: 20.w),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Quick jump buttons (+5, +10, +20)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAddChip('+5', () => _setQuantity(_quantity + 5)),
              SizedBox(width: 8.w),
              _buildAddChip('+10', () => _setQuantity(_quantity + 10)),
              SizedBox(width: 8.w),
              _buildAddChip('+20', () => _setQuantity(_quantity + 20)),
            ],
          ),
          SizedBox(height: 20.h),

          Text(
            'Quick Presets (Strips / Boxes)',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted),
          ),
          SizedBox(height: 8.h),

          // Preset grid/chips
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _presets.map((p) {
              final val = p['value'] as int;
              final label = p['label'] as String;
              final isSelected = _quantity == val;
              return InkWell(
                onTap: () => _setQuantity(val),
                borderRadius: AppRadius.sm,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : context.colorSurface,
                    borderRadius: AppRadius.sm,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : context.colorBorder,
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : context.colorTextPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),

          HealMealButton(
            label: 'Confirm Quantity ($_quantity)',
            onPressed: () {
              widget.onQuantitySelected(_quantity);
              Navigator.of(context).pop();
            },
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildAddChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.5),
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
