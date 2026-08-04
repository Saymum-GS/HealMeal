import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as b;
import '../utils/app_layout.dart';
import '../config.dart';
import '../../features/cart/cart_cubit.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/chat/chat_notification_cubit.dart';
import '../services.dart'; // For getIt
import '../repositories.dart'; // For ChatRepository
import 'bottom_nav.dart';
import 'guest_sheet.dart';
import 'cart_badge_icon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Removed local _showGuestAccountSheet

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartCubit>().totalCount;
    final currentIndex = navigationShell.currentIndex;

    final isGuest = context.watch<AuthCubit>().state is AuthUnauthenticated;

    void onNavigate(int index) {
      if (isGuest && (index == 3 || index == 4)) {
        showGuestAccountSheet(context);
        return;
      }
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppLayout.isCompact(context)) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: HealMealBottomNav(
              currentIndex: currentIndex,
              cartCount: cartCount,
              isGuest: isGuest,
              onTap: onNavigate,
            ),
            floatingActionButton: currentIndex == 1
                ? null
                : _buildChatFab(context),
          );
        }

        // Tablet/Desktop view
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onNavigate,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront_rounded),
                    label: Text('Shop'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.science_outlined),
                    selectedIcon: Icon(Icons.science_rounded),
                    label: Text('Lab Test'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: Text('Orders'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Account'),
                  ),
                ],
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: CartBadgeIcon(),
                    ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1),
              Expanded(child: navigationShell),
            ],
          ),
          floatingActionButton: currentIndex == 1
              ? null
              : _buildChatFab(context),
        );
      },
    );
  }

  Widget? _buildChatFab(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String userId = '';

    if (authState is AuthAuthenticated) {
      userId = authState.userId;
    }

    Widget baseFab(Widget iconWidget) {
      return FloatingActionButton.extended(
        onPressed: () {
          context.push('/chat');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: iconWidget,
        label: Text(
          'Support',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      );
    }

    if (userId.isEmpty) {
      return baseFab(Icon(Icons.chat_bubble_outline_rounded));
    }

    return BlocProvider(
      create: (_) => ChatNotificationCubit(getIt<ChatRepository>(), userId),
      child: BlocBuilder<ChatNotificationCubit, int>(
        builder: (context, unreadCount) {
          return baseFab(
            b.Badge(
              showBadge: unreadCount > 0,
              badgeContent: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              position: b.BadgePosition.topEnd(top: -12, end: -8),
              badgeStyle: b.BadgeStyle(
                badgeColor: AppColors.error,
                padding: EdgeInsets.all(4),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded),
            ),
          );
        },
      ),
    );
  }
}
