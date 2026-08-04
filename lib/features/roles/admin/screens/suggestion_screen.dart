import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healmeal_app/core/config.dart';
import '../../../../core/widgets.dart';
import '../admin_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminSuggestionScreen extends StatelessWidget {
  const AdminSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'User Suggestions', showBack: true),
      body: BlocBuilder<AdminSuggestionCubit, AdminSuggestionState>(
        builder: (context, state) {
          if (state.suggestions.isEmpty) {
            return Center(child: Text("No suggestions yet."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: state.suggestions.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final suggestion = state.suggestions[index];
              return Dismissible(
                key: Key(suggestion.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  try {
                    await context.read<AdminSuggestionCubit>().deleteSuggestion(
                      suggestion.id,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      // To fully fix dismissible revert, we should ideally reload state, 
                      // but since state is stream-based, it will jump back on its own or we show an error.
                    }
                  }
                },
                child: Card(
                  child: ListTile(
                    title: Text(
                      suggestion.productName,
                      style: AppTextStyles.h3,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (suggestion.brandName != null &&
                            suggestion.brandName!.isNotEmpty)
                          Text("Brand: ${suggestion.brandName}"),
                        if (suggestion.reason != null &&
                            suggestion.reason!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Reason: ${suggestion.reason}",
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      tooltip: 'Mark as Resolved',
                      onPressed: () async {
                        try {
                          await context.read<AdminSuggestionCubit>().deleteSuggestion(
                            suggestion.id,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
