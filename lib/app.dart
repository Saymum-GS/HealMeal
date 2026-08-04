import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/localization.dart';
import 'core/router.dart';
import 'core/theme.dart';

import 'features/auth/auth_cubit.dart';

class HealMealApp extends StatefulWidget {
  const HealMealApp({super.key});

  @override
  State<HealMealApp> createState() => _HealMealAppState();
}

class _HealMealAppState extends State<HealMealApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              title: 'HealMeal',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              locale: locale,
              supportedLocales: [Locale('en'), Locale('bn')],
              localizationsDelegates: AppTheme.localizationsDelegates,
              routerConfig: _router,
            );
          },
        );
      },
    );
  }
}
