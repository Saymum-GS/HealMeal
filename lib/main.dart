import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/account/notification_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';
import 'features/products/product_cubit.dart';
import 'features/products/wishlist_cubit.dart';
import 'core/localization.dart';
import 'core/theme.dart';
import 'core/utils.dart';
import 'features/auth/auth_cubit.dart';
import 'features/cart/cart_cubit.dart';
import 'features/orders/orders_cubit.dart';
import 'features/home/cubit/home_cubit.dart';

import 'firebase_options.dart';
import 'core/services.dart';
import 'core/repositories.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error\n$stack');
      return true;
    };

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Could not load .env file: $e");
    }

    await AppSession.init();

    bool serviceLocatorReady = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously().timeout(
            Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint('Anonymous sign-in failed/timeout: $e');
        }
      }

      await setupServiceLocator();
      serviceLocatorReady = true;

      // Defer NotificationService init after first frame to avoid freeze
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService.init();
      });
    } catch (e, stackTrace) {
      debugPrint("Firebase/ServiceLocator initialization error: $e");
      // DO NOT SWALLOW FIREBASE INIT ERRORS
      throw Exception(
        "FATAL: Firebase Initialization Failed.\nError: $e\nStackTrace: $stackTrace",
      );
    }

    final themeCubit = ThemeCubit();
    final localeCubit = LocaleCubit();
    final cartCubit = CartCubit();
    final productCubit = ProductCubit();
    final wishlistCubit = WishlistCubit();

    HomeCubit? homeCubit;
    if (serviceLocatorReady) {
      try {
        homeCubit = HomeCubit(
          articleRepository: getIt<ArticleRepository>(),
          settingsRepository: getIt<SettingsRepository>(),
          productRepository: getIt<ProductRepository>(),
        );
      } catch (e) {
        debugPrint("HomeCubit init failed: $e");
      }
    }

    homeCubit ??= HomeCubit.empty();

    try {
      await Future.wait<void>([
        themeCubit.loadSavedTheme(),
        localeCubit.loadSavedLocale(),
        wishlistCubit.loadWishlist(),
      ]);
    } catch (e) {
      debugPrint("Pre-launch load error: $e");
    }

    if (serviceLocatorReady) {
      productCubit.load();
    }

    runApp(
      ScreenUtilInit(
        designSize: Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: themeCubit),
              BlocProvider.value(value: localeCubit),
              BlocProvider.value(value: productCubit),
              BlocProvider.value(value: wishlistCubit),
              BlocProvider(create: (_) => AuthCubit()),
              BlocProvider(
                create: (context) =>
                    NotificationCubit(authCubit: context.read<AuthCubit>()),
              ),
              BlocProvider(create: (_) => OrdersCubit()..load()),
              BlocProvider.value(value: cartCubit),
              BlocProvider.value(value: homeCubit!),
            ],
            child: HealMealApp(),
          );
        },
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Startup error: $error\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24.0.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64.w),
                SizedBox(height: 16.h),
                Text(
                  'App crashed on startup',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      '$error\n$stackTrace',
                      style: TextStyle(fontSize: 12.sp, color: Colors.red),
                    ),
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
