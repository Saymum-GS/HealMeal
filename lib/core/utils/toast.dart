import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ToastType { success, error, info }

class AppToast {
  static OverlayEntry? _overlayEntry;
  static _ToastWidgetState? _activeToastState;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (_overlayEntry != null && _activeToastState != null) {
      // If a toast is already visible, trigger its dismiss animation first
      _activeToastState?.dismiss().then((_) {
        if (!context.mounted) return;
        _showNewToast(context, message, type, actionLabel, onAction);
      });
    } else {
      _showNewToast(context, message, type, actionLabel, onAction);
    }
  }

  static void _showNewToast(
    BuildContext context,
    String message,
    ToastType type,
    String? actionLabel,
    VoidCallback? onAction,
  ) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _activeToastState = null;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void registerState(_ToastWidgetState state) {
    _activeToastState = state;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppToast.registerState(this);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: Offset(0.0, -1.5),
          end: Offset(0.0, 0.2), // Slight padding from top
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        );

    _controller.forward();

    // Only auto-dismiss if there's no action button, to give users time to click it.
    if (widget.actionLabel == null) {
      _timer = Timer(Duration(seconds: 3), () {
        dismiss();
      });
    } else {
      // Give them more time if there is an action
      _timer = Timer(Duration(seconds: 6), () {
        dismiss();
      });
    }
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    if (mounted) {
      await _controller.reverse();
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (widget.type) {
      case ToastType.success:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.primary;
        break;
      case ToastType.error:
        icon = Icons.error_rounded;
        iconColor = AppColors.error;
        break;
      case ToastType.info:
        icon = Icons.info_rounded;
        iconColor = AppColors.accentBlue;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24.w,
      right: 24.w,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: iconColor, size: 20.w),
                      SizedBox(width: 10.w),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.actionLabel != null &&
                          widget.onAction != null) ...[
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: () {
                            dismiss();
                            widget.onAction!();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
