import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/cart_cubit.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({
    super.key,
    this.color,
    this.size = 24.0,
    this.badgeColor = AppColors.error,
  });

  final Color? color;
  final double size;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final fgColor =
        color ?? Theme.of(context).iconTheme.color ?? AppColors.textPrimary;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count = state.items.length;
        return IconButton(
          onPressed: () => context.push('/cart'),
          icon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, color: fgColor, size: size),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    tween: Tween(begin: 0.0, end: 1.0),
                    key: ValueKey(count),
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
