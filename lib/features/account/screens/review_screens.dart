import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config.dart';
import '../../../core/widgets.dart';
import '../../../core/models.dart';
import '../../orders/orders_cubit.dart';
import '../account_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Medicine Reviews', showBack: true),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (!state.loaded) {
            return Center(child: CircularProgressIndicator());
          }

          final deliveredOrders = state.orders
              .where((o) => o.status == OrderStatus.delivered)
              .toList();
          final List<Product> reviewed = deliveredOrders
              .expand((order) => order.items.map((item) => item.product))
              .toSet()
              .toList();

          if (reviewed.isEmpty) {
            return EmptyStateWidget(
              type: EmptyStateType.orders,
              customTitle: 'No Reviews Yet',
              customBody:
                  'You have not reviewed any products or have no delivered orders.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: reviewed.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final product = reviewed[index];
              return CardSection(
                title: product.drugName,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.accentGold,
                          size: 20.w,
                        ),
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.accentGold,
                          size: 20.w,
                        ),
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.accentGold,
                          size: 20.w,
                        ),
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.accentGold,
                          size: 20.w,
                        ),
                        Icon(
                          Icons.star_border_rounded,
                          color: AppColors.accentGold,
                          size: 20.w,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap to write a review for this product.',
                      style: TextStyle(color: context.colorTextSecondary),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
