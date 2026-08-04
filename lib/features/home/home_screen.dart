import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import 'home_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<HomeCubit>().load(forceRefresh: true);
            },
            child: CustomScrollView(
              physics: BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 1. Header with location/cart
                HomeAppBar(),

                // 2. Search bar
                SearchHero(),

                // 3. Quick actions: Medicines, Upload Rx, Lab Tests, Reorder
                PrimaryActionGrid(),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        <Widget>[
                              // 4. Prescription upload strip
                              PrescriptionHeroStrip(),

                              // 5. Continue care / common medicines
                              QuickReorderWidget(),
                              SizedBox(height: 16.h),

                              // 6. Diabetes care
                              MedicineShelf(
                                products: homeState.diabetesProducts,
                                title: 'Diabetes care',
                                subtitle:
                                    'Sugar substitutes, test strips & more',
                                icon: Icons.bloodtype_rounded,
                                accentColor: Colors.red,
                                onSeeAll: () => context.push(
                                  '/products?category=diabetes_care',
                                ),
                              ),

                              // 7. Heart & blood pressure
                              MedicineShelf(
                                products: homeState.heartProducts,
                                title: 'Heart & blood pressure',
                                subtitle: 'Keep your heart healthy',
                                icon: Icons.favorite_rounded,
                                accentColor: Colors.pink,
                                onSeeAll: () => context.push(
                                  '/products?category=cardiovascular_system',
                                ),
                              ),

                              // 8. Cold, fever & allergy (Generic shelf if data exists)
                              MedicineShelf(
                                products: homeState.featuredProducts
                                    .take(8)
                                    .toList(),
                                title: 'Featured medicines',
                                subtitle: 'Most popular choices',
                                icon: Icons.star_rounded,
                                accentColor: AppColors.primary,
                                onSeeAll: () =>
                                    context.push('/products?featured=true'),
                              ),

                              // 9. Lab tests at home
                              LabTestHomeModule(),

                              // 10. Under ৳100
                              MedicineShelf(
                                products: homeState.under100Products,
                                title: 'Under ৳100',
                                subtitle: 'Budget friendly essentials',
                                icon: Icons.payments_rounded,
                                accentColor: Colors.green,
                                onSeeAll: () =>
                                    context.push('/products?maxPrice=100'),
                              ),

                              // 11. Skin care / vitamins
                              MedicineShelf(
                                products: homeState.skinCareProducts,
                                title: 'Skin care',
                                subtitle: 'Dermatologist recommended',
                                icon: Icons.face_retouching_natural_rounded,
                                accentColor: Colors.purple,
                                onSeeAll: () => context.push(
                                  '/products?category=dermatological_preparations',
                                ),
                              ),

                              MedicineShelf(
                                products: homeState.vitaminProducts,
                                title: 'Vitamins & supplements',
                                subtitle: 'Boost your immunity',
                                icon: Icons.auto_awesome_rounded,
                                accentColor: Colors.orange,
                                onSeeAll: () => context.push(
                                  '/products?category=vitamins_minerals',
                                ),
                              ),

                              // 12. Trust strip
                              TrustStrip(),

                              SizedBox(height: 32.h),
                            ]
                            .animate(interval: 100.ms)
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOut),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
