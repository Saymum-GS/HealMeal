import 'package:flutter/material.dart';
import '../config.dart';
import '../utils.dart';

enum PriceDisplaySize { small, medium, large }

class PriceDisplay extends StatelessWidget {
  const PriceDisplay({
    super.key,
    required this.mrp,
    required this.salePrice,
    this.size = PriceDisplaySize.medium,
  });

  final double mrp;
  final double salePrice;
  final PriceDisplaySize size;

  @override
  Widget build(BuildContext context) {
    final saleStyle = switch (size) {
      PriceDisplaySize.small => AppTextStyles.priceSmall,
      PriceDisplaySize.medium => AppTextStyles.priceMedium,
      PriceDisplaySize.large => AppTextStyles.priceLarge,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppFormatters.taka(mrp),
          style: AppTextStyles.bodySmall.copyWith(
            color: context.colorTextMuted,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        Text(
          AppFormatters.taka(salePrice),
          style: saleStyle.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
