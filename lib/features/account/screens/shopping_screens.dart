import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import '../../../core/repositories.dart';
import '../../../core/models.dart';

import '../../cart/cart_cubit.dart';
import '../../../core/services.dart';

import '../../products/wishlist_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (BuildContext context, WishlistState pState) {
        final products = pState.products;
        return Scaffold(
          appBar: HealMealAppBar(
            title: 'My Wishlist (${products.length})',
            showBack: true,
          ),
          body: products.isEmpty
              ? EmptyStateWidget(
                  type: EmptyStateType.search,
                  customTitle: 'Your wishlist is empty',
                  customBody: 'Tap the heart on any product to save it here.',
                  actionLabel: 'Browse Medicines',
                  onAction: () => context.go('/home'),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: AppLayout.productGridDelegate(
                    MediaQuery.sizeOf(context).width,
                  ),
                  itemCount: products.length,
                  itemBuilder: (BuildContext context, int index) {
                    final product = products[index];
                    return Column(
                      children: <Widget>[
                        Expanded(
                          child: ProductCard(
                            product: product,
                            onTap: () => context.push('/product/${product.id}'),
                            onAddToCart: () =>
                                context.read<CartCubit>().addItem(product),
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.subtle,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            'Added: 2 days ago',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyXSmall.copyWith(
                              color: context.colorTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class NotifiedProductsScreen extends StatefulWidget {
  const NotifiedProductsScreen({super.key});

  @override
  State<NotifiedProductsScreen> createState() => _NotifiedProductsScreenState();
}

class _NotifiedProductsScreenState extends State<NotifiedProductsScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    final ids = context.read<WishlistCubit>().state.notifiedProductIds.toList();
    _productsFuture = getIt<ProductRepository>().getProductsByIds(ids);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (BuildContext context, WishlistState state) {
        final notifiedIds = state.notifiedProductIds.toList();
        return Scaffold(
          appBar: HealMealAppBar(title: 'Notify Me - Medicines', showBack: true),
          body: notifiedIds.isEmpty
              ? Center(child: Text('No medicines in your notify list.'))
              : FutureBuilder<List<Product>>(
                  future: _productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final fetchedProducts = snapshot.data ?? [];
                    final notified = fetchedProducts
                        .where((p) => notifiedIds.contains(p.id))
                        .toList();

                    if (notified.isEmpty) {
                      return Center(child: Text('No medicines found.'));
                    }
                    return ListView(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      children: <Widget>[
                        InfoBanner(
                          title: 'Back in stock alerts',
                          body:
                              'We will notify you when these out-of-stock products are available again.',
                          type: InfoBannerType.info,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ...notified.map((product) {
                          return Container(
                            margin: EdgeInsets.only(bottom: AppSpacing.md),
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: AppRadius.lg,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 60.w,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: AppRadius.md,
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        product.drugName,
                                        style: AppTextStyles.h3,
                                      ),
                                      Text(
                                        product.manufacturer,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: context.colorTextSecondary,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Out of Stock',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<WishlistCubit>()
                                        .removeNotifiedProduct(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Removed from notify list',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Remove'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class SuggestProductScreen extends StatefulWidget {
  const SuggestProductScreen({super.key});

  @override
  State<SuggestProductScreen> createState() => _SuggestProductScreenState();
}

class _SuggestProductScreenState extends State<SuggestProductScreen> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _productController.dispose();
    _brandController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Suggest a Medicine', showBack: true),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 52.w,
            color: AppColors.accentGold,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Help us stock what you need',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Can\'t find a medicine or healthcare product? Tell us and we\'ll try to add it.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxxl),
          HealMealTextField(
            controller: _productController,
            label: 'Medicine Name',
          ),
          SizedBox(height: AppSpacing.lg),
          HealMealTextField(
            controller: _brandController,
            label: 'Brand Name (optional)',
          ),
          SizedBox(height: AppSpacing.lg),
          HealMealTextField(
            controller: _reasonController,
            label: 'Why do you need it? (optional)',
            maxLines: 3,
            minLines: 3,
          ),
          SizedBox(height: AppSpacing.xl),
          HealMealButton(
            label: 'Submit Suggestion',
            size: ButtonSize.large,
            isLoading: _loading,
            onPressed: () async {
              if (_productController.text.isEmpty) return;

              setState(() => _loading = true);
              try {
                final userId = AppSession.userId;
                if (userId == null) return;

                final repo = SuggestionRepository();
                final suggestion = ProductSuggestion(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  productName: _productController.text,
                  brandName: _brandController.text,
                  reason: _reasonController.text,
                  createdAt: DateTime.now(),
                  userId: userId,
                );

                await repo.submitSuggestion(suggestion);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thank you! Suggestion received.')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class CashbackWalletScreen extends StatelessWidget {
  const CashbackWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<CartCubit>().state.walletBalance;
    return Scaffold(
      appBar: HealMealAppBar(title: 'Cashback Wallet', showBack: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 64.w,
              color: AppColors.primary,
            ),
            SizedBox(height: 16.h),
            Text('Available Balance', style: AppTextStyles.h2),
            SizedBox(height: 8.h),
            Text(
              AppFormatters.taka(balance, decimals: 2),
              style: AppTextStyles.priceLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<AppOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final userId = AppSession.userId;
    if (userId != null) {
      _ordersFuture = getIt<OrderRepository>().getUserOrders(userId);
    } else {
      _ordersFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = AppSession.userId;
    if (userId == null) {
      return Scaffold(
        appBar: HealMealAppBar(title: 'Transaction History', showBack: true),
        body: Center(child: Text('Please login to view transactions.')),
      );
    }
    return Scaffold(
      appBar: HealMealAppBar(title: 'Transaction History', showBack: true),
      body: FutureBuilder<List<AppOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final allOrders = snapshot.data ?? [];
          final transactions = allOrders
              .where((o) => o.cashbackUsed > 0)
              .toList();

          if (transactions.isEmpty) {
            return EmptyStateWidget(
              type: EmptyStateType.orders,
              customTitle: 'No Transactions',
              customBody: 'You haven\'t used any cashback yet.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final order = transactions[index];
              return ListTile(
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                ),
                title: Text('Order ${order.id.replaceAll('#', '')}'),
                subtitle: Text(AppFormatters.shortDate(order.placedAt)),
                trailing: Text(
                  '- ${AppFormatters.taka(order.cashbackUsed)}',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.md,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
