import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';

class HealMealButton extends StatefulWidget {
  const HealMealButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.filled,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.prefixIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final IconData? prefixIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  @override
  State<HealMealButton> createState() => _HealMealButtonState();
}

class _HealMealButtonState extends State<HealMealButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _height => switch (widget.size) {
    ButtonSize.large => 52.h,
    ButtonSize.medium => 44.h,
    ButtonSize.small => 36.h,
  };

  @override
  Widget build(BuildContext context) {
    final Color filledBackground = widget.backgroundColor ?? AppColors.primary;
    final Brightness brightness = ThemeData.estimateBrightnessForColor(
      filledBackground,
    );
    final Color resolvedFilledForeground =
        widget.foregroundColor ??
        (brightness == Brightness.dark ? AppColors.white : AppColors.textDark);
    final Color resolvedLineForeground =
        widget.foregroundColor ?? AppColors.primary;

    final child = AnimatedSwitcher(
      duration: Duration(milliseconds: 250),
      child: widget.isLoading
          ? SizedBox(
              key: ValueKey('loader'),
              width: 18.w,
              height: 18.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.type == ButtonType.filled
                    ? resolvedFilledForeground
                    : resolvedLineForeground,
              ),
            )
          : Row(
              key: ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon, size: 18.w),
                  SizedBox(width: AppSpacing.sm),
                ],
                Text(widget.label, overflow: TextOverflow.ellipsis),
              ],
            ),
    );

    final filledStyle = FilledButton.styleFrom(
      minimumSize: Size(widget.width ?? 0, _height),
      backgroundColor: filledBackground,
      foregroundColor: resolvedFilledForeground,
      disabledBackgroundColor: AppColors.subtle,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      textStyle: AppTextStyles.labelLarge,
      elevation: 4,
      shadowColor: filledBackground.withOpacity(0.4),
    );

    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: Size(widget.width ?? 0, _height),
      side: BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      textStyle: AppTextStyles.labelLarge,
      foregroundColor: resolvedLineForeground,
    );

    final textStyle = TextButton.styleFrom(
      minimumSize: Size(widget.width ?? 0, _height),
      textStyle: AppTextStyles.labelLarge,
      foregroundColor: resolvedLineForeground,
    );

    Widget button = switch (widget.type) {
      ButtonType.filled => FilledButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: filledStyle,
        child: child,
      ),
      ButtonType.outlined => OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: outlinedStyle,
        child: child,
      ),
      ButtonType.text => TextButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: textStyle,
        child: child,
      ),
    };

    return Semantics(
      label: widget.isLoading ? '${widget.label}, loading' : widget.label,
      button: true,
      child: MouseRegion(
        cursor: widget.isLoading
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) {
            if (!widget.isLoading && widget.onPressed != null) {
              _controller.forward();
            }
          },
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(scale: _scaleAnimation, child: button),
        ),
      ),
    );
  }
}

enum ButtonType { filled, outlined, text }

enum ButtonSize { large, medium, small }
