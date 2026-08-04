import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/category.dart';
import '../../core/repositories.dart';
import '../../core/services.dart';
import '../../core/config.dart';
import '../../core/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<AppCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = getIt<CategoryRepository>().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: HealMealAppBar(
              title: 'Categories',
              showSearch: true,
              showCart: true,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final categories = (snapshot.data ?? [])
            .where((cat) => cat.id != 'flash-sale' && cat.isActive)
            .toList();

        return Scaffold(
          appBar: HealMealAppBar(
            title: 'Categories',
            showSearch: true,
            showCart: true,
          ),
          body: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 112,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () => context.push('/category/${category.id}'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 28.w,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          category.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
