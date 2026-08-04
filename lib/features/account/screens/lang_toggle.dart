import 'package:flutter/material.dart';
import '../../../core/config.dart';

class LangToggle extends StatelessWidget {
  const LangToggle({
    super.key,
    required this.isBangla,
    required this.onEnglish,
    required this.onBangla,
  });

  final bool isBangla;
  final VoidCallback onEnglish;
  final VoidCallback onBangla;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.pill,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: <Widget>[
          _LangChoice(label: 'EN', active: !isBangla, onTap: onEnglish),
          _LangChoice(label: 'বাং', active: isBangla, onTap: onBangla),
        ],
      ),
    );
  }
}

class _LangChoice extends StatelessWidget {
  const _LangChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.white : context.colorTextSecondary,
          ),
        ),
      ),
    );
  }
}
