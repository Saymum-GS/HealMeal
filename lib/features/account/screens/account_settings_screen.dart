import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config.dart';
import '../../../core/widgets.dart';
import '../../../core/theme.dart';
import '../../../core/localization.dart';
import '../account_widgets.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      appBar: HealMealAppBar(title: 'Settings', showBack: true),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          CardSection(
            title: 'Appearance',
            child: SwitchListTile(
              value: isDark,
              onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
              contentPadding: EdgeInsets.zero,
              title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          CardSection(
            title: 'Language',
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ChoiceChip(
                    label: Text('English'),
                    selected: !context.isBangla,
                    onSelected: (_) => context.read<LocaleCubit>().setEnglish(),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ChoiceChip(
                    label: Text('বাংলা'),
                    selected: context.isBangla,
                    onSelected: (_) => context.read<LocaleCubit>().setBangla(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
