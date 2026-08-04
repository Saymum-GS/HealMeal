import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';
import '../../../../core/models.dart';
import '../admin_cubit.dart';
import 'components.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _roleFilter; // null = all, 'user', 'admin'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserCubit>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWalletAdjustmentDialog(BuildContext context, AppUser user) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust Wallet Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance: ৳${user.walletBalance.toStringAsFixed(2)}'),
            SizedBox(height: AppSpacing.sm),
            HealMealTextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              label: 'Adjustment Amount (e.g. 50 or -50)',
            ),
          ],
        ),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(ctx),
            label: 'Cancel',
          ),
          HealMealButton(
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val != 0.0) {
                try {
                  await context.read<AdminUserCubit>().updateWalletBalance(
                    user.id,
                    val,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    AppToast.show(
                      ctx,
                      'Wallet balance adjusted by ৳$val.',
                      type: ToastType.success,
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    AppToast.show(
                      ctx,
                      'Failed to adjust wallet balance: $e',
                      type: ToastType.error,
                    );
                  }
                }
              }
            },
            label: 'Apply',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'User Management', showBack: true),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: HealMealTextField(
              controller: _searchController,
              label: 'Search by name or phone',
              onChanged: (val) =>
                  setState(() => _query = val.trim().toLowerCase()),
            ),
          ),
          // Role filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All'),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                ),
                SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Text('Users'),
                  selected: _roleFilter == 'user',
                  onSelected: (_) => setState(() => _roleFilter = 'user'),
                ),
                SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Text('Admins'),
                  selected: _roleFilter == 'admin',
                  onSelected: (_) => setState(() => _roleFilter = 'admin'),
                ),
                SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Text('Suspended'),
                  selected: _roleFilter == 'suspended',
                  onSelected: (_) => setState(() => _roleFilter = 'suspended'),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<AdminUserCubit, AdminUserState>(
              builder: (context, state) {
                if (state.isLoading && state.allUsers.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                var users = state.allUsers;

                // Apply search filter
                if (_query.isNotEmpty) {
                  users = users.where((u) {
                    return u.name.toLowerCase().contains(_query) ||
                        u.phone.contains(_query) ||
                        (u.email?.toLowerCase().contains(_query) ?? false);
                  }).toList();
                }

                // Apply role filter
                if (_roleFilter == 'suspended') {
                  users = users.where((u) => !u.isActive).toList();
                } else if (_roleFilter != null) {
                  users = users.where((u) => u.role == _roleFilter).toList();
                }

                if (users.isEmpty) {
                  return Center(child: Text('No users match this filter.'));
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.9) {
                      context.read<AdminUserCubit>().loadMoreUsers();
                    }
                    return true;
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: users.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index == users.length) {
                        return Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final user = users[index];
                      return RoleCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage:
                                  (user.photoUrl != null &&
                                      user.photoUrl!.isNotEmpty)
                                  ? ImageBase64Util.resolveProvider(
                                      user.photoUrl!,
                                    )
                                  : null,
                              child:
                                  (user.photoUrl == null ||
                                      user.photoUrl!.isEmpty)
                                  ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  Text(
                                    user.phone,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: context.colorTextSecondary,
                                    ),
                                  ),
                                  if (user.email != null)
                                    Text(
                                      user.email!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.colorTextSecondary,
                                      ),
                                    ),
                                  if (!user.isActive)
                                    Text(
                                      'Suspended',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  Text(
                                    'Wallet: ৳${user.walletBalance.toStringAsFixed(2)}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: user.role),
                            SizedBox(width: AppSpacing.sm),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded),
                              onSelected: (action) async {
                                try {
                                  if (action == 'adjust_wallet') {
                                    _showWalletAdjustmentDialog(context, user);
                                  } else if (action == 'toggle_status') {
                                    await context
                                        .read<AdminUserCubit>()
                                        .toggleUserActive(
                                          user.id,
                                          !user.isActive,
                                        );
                                    if (context.mounted) {
                                      AppToast.show(
                                        context,
                                        user.isActive
                                            ? 'User suspended.'
                                            : 'User reinstated.',
                                        type: ToastType.success,
                                      );
                                    }
                                  } else {
                                    await context
                                        .read<AdminUserCubit>()
                                        .updateRole(user.id, action);
                                    if (context.mounted) {
                                      AppToast.show(
                                        context,
                                        'Role updated to $action.',
                                        type: ToastType.success,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      'Failed to update user: $e',
                                      type: ToastType.error,
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'adjust_wallet',
                                  child: Text('Adjust Wallet Balance'),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'user',
                                  child: Text('Set as User'),
                                ),
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Set as Admin'),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'toggle_status',
                                  child: Text(
                                    user.isActive
                                        ? 'Suspend User'
                                        : 'Reinstate User',
                                    style: TextStyle(
                                      color: user.isActive
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
