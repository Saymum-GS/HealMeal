import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
import 'utils.dart';
import 'services.dart';
import 'repositories.dart';
import 'widgets/adaptive_scaffold.dart';
import 'services/groq_service.dart';

import '../../features/account/account_screens.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/splash/splash_screens.dart';
import '../../features/cart/cart_screens.dart';
import '../../features/checkout/checkout_screens.dart';
import '../../features/checkout/checkout_cubit.dart';
import '../../features/orders/orders_cubit.dart';
import '../../features/home/home_screens.dart';
import '../../features/labs/lab_screens.dart';
import '../../features/labs/lab_cubit.dart';
import '../../features/labs/lab_package_list_screen.dart';
import '../../features/labs/lab_package_detail_screen.dart';
import '../../features/products/product_screens.dart';
import '../../features/roles/admin/admin_screens.dart';
import '../../features/roles/admin/screens/admin_articles_screen.dart';
import '../../features/roles/admin/admin_moderation_screens.dart';
import '../../features/roles/admin/admin_cubit.dart';
import '../../features/search/search_screens.dart';
import '../../features/search/search_cubit.dart';
import '../../features/static/static_screens.dart';
import '../../features/chat/chat_screens.dart';
import '../../features/chat/chat_cubit.dart';
import '../../features/shop/shop_landing_screen.dart';
import '../../features/content/article_list_screen.dart';
import '../../features/content/article_detail_screen.dart';
import '../../features/support/support_entry_screen.dart';
import '../../features/products/product_cubit.dart';
import '../../features/prescriptions/prescriptions_screens.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._authCubit) {
    _authCubit.stream.listen((state) {
      notifyListeners();
    });
  }

  final AuthCubit _authCubit;
}

Set<String> _authEntryRoutes = <String>{
  '/splash',
  '/onboarding',
  '/value_banner',
  '/login',
  '/register',
  '/forgot-password',
};

Set<String> _publicRoutes = <String>{
  '/about',
  '/blog',
  '/contact',
  '/doctor-consultation',
  '/faq',
  '/jobs',
  '/privacy',
  '/return-policy',
  '/terms',
};

Set<String> _guestBrowseRoutes = <String>{
  '/home',
  '/categories',
  '/category',
  '/product',
  '/products',
  '/brand',
  '/labs',
  '/search',
  '/cart',
  '/account',
  '/chat',
};

bool _matchesPath(String location, String route) {
  return location == route || location.startsWith('$route/');
}

bool _isPublicLocation(String location) {
  for (final String route in _authEntryRoutes) {
    if (_matchesPath(location, route)) return true;
  }
  for (final String route in _publicRoutes) {
    if (_matchesPath(location, route)) return true;
  }
  return false;
}

bool _isGuestBrowsable(String location) {
  for (final String route in _guestBrowseRoutes) {
    if (_matchesPath(location, route)) return true;
  }
  return false;
}

bool _isAdminArea(String location) => _matchesPath(location, '/admin');

String? _redirectGuard(GoRouterState state, AuthCubit authCubit) {
  final authState = authCubit.state;
  if (authState is AuthInitial) return null;

  final String location = state.uri.path;
  final bool loggedIn = authState is AuthAuthenticated;
  final UserRole? role = authState is AuthAuthenticated ? authState.role : null;

  final String encodedLocation = Uri.encodeComponent(location);

  if (_isPublicLocation(location)) {
    if (loggedIn &&
        _authEntryRoutes.any((String route) => _matchesPath(location, route))) {
      return role?.homeRoute ?? '/home';
    }
    return null;
  }

  if (_isGuestBrowsable(location)) {
    if (location.startsWith('/labs/book/')) {
      if (!loggedIn) return '/login?redirect=$encodedLocation';
    }
    return null;
  }

  if (!loggedIn) {
    return '/login?redirect=$encodedLocation';
  }

  if (_isAdminArea(location) && role?.homeRoute != '/admin') {
    return '/home';
  }

  return null;
}

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterNotifier(authCubit),
    redirect: (_, GoRouterState state) => _redirectGuard(state, authCubit),
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => FeatureSplashScreen()),
      GoRoute(
        path: '/value_banner',
        builder: (_, __) => PharmacyValueBannerScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (_, state) =>
            LoginScreen(redirectUrl: state.uri.queryParameters['redirect']),
      ),
      GoRoute(path: '/register', builder: (_, __) => RegistrationScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => ForgotPasswordScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  LabTestCubit(repository: getIt<LabTestRepository>())..load(),
            ),
          ],
          child: child,
        ),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AdaptiveScaffold(navigationShell: navigationShell),
            branches: <StatefulShellBranch>[
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => HomeScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/search',
                    builder: (context, state) => BlocProvider(
                      create: (_) => SearchCubit(
                        repository: getIt<ProductRepository>(),
                        historyRepository: getIt<SearchHistoryRepository>(),
                        groqService: getIt<GroqService>(),
                      ),
                      child: SearchScreen(
                        initialQuery: state.uri.queryParameters['q'],
                        initialAi: state.uri.queryParameters['ai'] == 'true',
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/labs',
                    builder: (context, state) => LabTestHomeScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/orders',
                    builder: (context, __) => OrderHistoryScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/account',
                    builder: (_, __) => AccountScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: '/cart', builder: (_, __) => CartScreen()),
          GoRoute(
            path: '/prescriptions/upload',
            builder: (_, __) => PrescriptionUploadScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (_, __) => CategoryListScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, GoRouterState state) =>
                ProductListScreen(queryParams: state.uri.queryParameters),
          ),
          GoRoute(
            path: '/product/:id',
            builder: (_, GoRouterState state) =>
                ProductDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/brand/:id',
            builder: (_, GoRouterState state) =>
                BrandScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/category/:slug',
            builder: (_, GoRouterState state) =>
                CategoryHomeScreen(slug: state.pathParameters['slug']!),
          ),

          // -- Labs unified routes --
          GoRoute(
            path: '/labs/packages',
            builder: (_, __) => LabPackageListScreen(),
          ),
          GoRoute(
            path: '/labs/packages/:id',
            builder: (_, state) => BlocBuilder<LabTestCubit, LabTestState>(
              builder: (context, cubitState) {
                final pkgId = state.pathParameters['id'];
                final pkg = cubitState.packages.firstWhereOrNull(
                  (p) => p.id == pkgId,
                );
                if (pkg == null && cubitState.status != LabTestStatus.loading) {
                  return Scaffold(
                    body: Center(child: Text('Package not found')),
                  );
                }
                return LabPackageDetailScreen(package: pkg!);
              },
            ),
          ),
          // NOTE: /labs/book/:id MUST come before /labs/:id to avoid wildcard conflict
          GoRoute(
            path: '/labs/book/:id',
            builder: (_, GoRouterState state) =>
                LabTestBookingScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/labs/:id',
            builder: (_, GoRouterState state) =>
                LabTestDetailScreen(id: state.pathParameters['id']!),
          ),
        ],

      ),

      ShellRoute(
        builder: (context, state, child) =>
            BlocProvider(create: (context) => CheckoutCubit(), child: child),
        routes: [
          GoRoute(
            path: '/checkout',
            builder: (context, __) => CheckoutScreen(),
          ),
          GoRoute(
            path: '/order-confirmed',
            builder: (_, __) => OrderConfirmedScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/orders/:id',
        builder: (_, GoRouterState state) =>
            OrderDetailScreen(id: state.pathParameters['id']!),
      ),

      GoRoute(path: '/shop', builder: (_, __) => ShopLandingScreen()),
      GoRoute(path: '/articles', builder: (_, __) => ArticleListScreen()),
      GoRoute(
        path: '/articles/:slug',
        builder: (_, state) =>
            ArticleDetailScreen(slug: state.pathParameters['slug']),
      ),

      GoRoute(path: '/support', builder: (_, __) => SupportEntryScreen()),

      GoRoute(path: '/account/edit', builder: (_, __) => EditProfileScreen()),
      GoRoute(
        path: '/account/addresses',
        builder: (_, __) => AddressBookScreen(),
      ),
      GoRoute(
        path: '/account/addresses/add',
        builder: (_, state) {
          final address = state.extra as Address?;
          return AddEditAddressScreen(address: address);
        },
      ),
      GoRoute(
        path: '/account/notifications',
        builder: (_, __) => NotificationListScreen(),
      ),
      GoRoute(
        path: '/account/product-reviews',
        builder: (context, __) => BlocProvider(
          create: (context) => OrdersCubit()..load(),
          child: ProductReviewsScreen(),
        ),
      ),
      GoRoute(
        path: '/account/manage-patients',
        builder: (_, __) => ManagePatientsScreen(),
      ),
      GoRoute(
        path: '/account/settings',
        builder: (_, __) => AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/account/lab-orders',
        builder: (_, __) => OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/account/lab-bookings',
        builder: (_, __) => OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/account/lab-reports',
        builder: (_, __) => LabReportsScreen(),
      ),
      GoRoute(path: '/account/wishlist', builder: (_, __) => WishlistScreen()),
      GoRoute(
        path: '/account/notified-products',
        builder: (_, __) => NotifiedProductsScreen(),
      ),
      GoRoute(
        path: '/account/suggest-product',
        builder: (_, __) => SuggestProductScreen(),
      ),
      GoRoute(
        path: '/account/cashback',
        builder: (_, __) => CashbackWalletScreen(),
      ),
      GoRoute(
        path: '/account/transactions',
        builder: (_, __) => TransactionHistoryScreen(),
      ),

      GoRoute(
        path: '/account/referral',
        builder: (_, __) => ReferAndEarnScreen(),
      ),

      GoRoute(path: '/about', builder: (_, __) => AboutUsScreen()),
      GoRoute(path: '/contact', builder: (_, __) => ContactScreen()),
      GoRoute(path: '/faq', builder: (_, __) => FaqScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => PrivacyPolicyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => TermsScreen()),
      GoRoute(path: '/return-policy', builder: (_, __) => ReturnPolicyScreen()),
      GoRoute(path: '/blog', builder: (_, __) => HealthTipsBlogScreen()),
      GoRoute(
        path: '/doctor-consultation',
        builder: (_, __) => DoctorConsultationScreen(),
      ),
      GoRoute(path: '/jobs', builder: (_, __) => CareersScreen()),

      // -- Admin Routes --
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  AdminOrderCubit(orderRepository: getIt<OrderRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  AdminUserCubit(userRepository: getIt<UserRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  AdminLabBookingCubit(labRepository: getIt<LabRepository>()),
            ),

            BlocProvider(create: (context) => AdminCategoriesCubit()),
            BlocProvider(
              create: (context) =>
                  AdminInventoryCubit(getIt<ProductRepository>()),
            ),

            BlocProvider(
              create: (context) => AdminSuggestionCubit(
                suggestionRepository: getIt<SuggestionRepository>(),
              ),
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, __) => AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, __) => UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/products/add',
            builder: (context, __) => ProductFormScreen(),
          ),

          GoRoute(
            path: '/admin/reviews',
            builder: (context, __) => AdminReviewsScreen(),
          ),
          GoRoute(
            path: '/admin/support',
            builder: (context, __) => AdminSupportScreen(),
          ),

          GoRoute(
            path: '/admin/settings',
            builder: (context, __) => AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => BlocProvider(
              create: (_) => ProductCubit()..setLifecycleStatus(null),
              child: AdminProductListScreen(
                categoryId: state.uri.queryParameters['category'],
              ),
            ),
          ),
          GoRoute(
            path: '/admin/inventory',
            builder: (context, __) => AdminInventoryScreen(),
          ),

          GoRoute(
            path: '/admin/coupons',
            builder: (context, __) => AdminCouponsScreen(),
          ),
          GoRoute(
            path: '/admin/suggestions',
            builder: (_, __) => AdminSuggestionScreen(),
          ),
          GoRoute(path: '/admin/faqs', builder: (_, __) => AdminFaqScreen()),
          GoRoute(
            path: '/admin/articles',
            builder: (_, __) => AdminArticlesScreen(),
          ),
          GoRoute(
            path: '/admin/lab-bookings',
            builder: (context, __) => AdminLabBookingScreen(),
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (context, __) => AdminCategoryScreen(),
          ),
          GoRoute(
            path: '/admin/products/edit/:id',
            builder: (context, GoRouterState state) =>
                ProductFormScreen(productId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, __) => AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/lab-tests',
            builder: (context, __) => AdminLabTestsCatalogScreen(),
          ),
          GoRoute(
            path: '/admin/chat',
            builder: (context, __) => AdminChatListScreen(),
          ),
          GoRoute(
            path: '/admin/chat/:userId',
            builder: (context, GoRouterState state) => BlocProvider(
              create: (context) => ChatCubit(
                getIt<ChatRepository>(),
                state.pathParameters['userId']!,
              ),
              child: ChatScreen(
                userId: state.pathParameters['userId']!,
                userName: state.uri.queryParameters['name'] ?? 'User',
                isAdmin: true,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/prescriptions',
            builder: (context, __) => AdminPrescriptionsScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/chat',
        builder: (context, __) {
          final authState = context.read<AuthCubit>().state;
          final userId =
              AppSession.userId ??
              FirebaseAuth.instance.currentUser?.uid ??
              AppSession.guestId;

          String userName;
          if (authState is AuthAuthenticated) {
            userName = (authState.name != null && authState.name!.isNotEmpty)
                ? authState.name!
                : (AppSession.phone ?? 'User');
          } else {
            final shortId = userId.length > 10
                ? userId.substring(userId.length - 5)
                : userId;
            userName = 'Guest-$shortId';
          }

          return BlocProvider(
            create: (_) => ChatCubit(getIt<ChatRepository>(), userId),
            child: ChatScreen(
              userId: userId,
              userName: userName,
              isAdmin: false,
            ),
          );
        },
      ),
    ],
  );
}
