import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../core/config.dart';

import '../cart/cart_cubit.dart';
import '../search/search_cubit.dart';
import 'ai_chat_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery, this.initialAi = false});
  final String? initialQuery;
  final bool initialAi;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialAi ? 1 : 0,
      child: Scaffold(
        appBar: HealMealAppBar(
          title: 'Search',
          showBack: true,
          showCart: true,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Normal Search'),
              Tab(text: 'AI Assistant'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: TabBarView(
          children: [
            _NormalSearchTab(
              initialQuery: widget.initialAi ? null : widget.initialQuery,
            ),
            AiChatScreen(
              initialQuery: widget.initialAi ? widget.initialQuery : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _NormalSearchTab extends StatefulWidget {
  const _NormalSearchTab({this.initialQuery});
  final String? initialQuery;

  @override
  State<_NormalSearchTab> createState() => _NormalSearchTabState();
}

class _NormalSearchTabState extends State<_NormalSearchTab> {
  late final TextEditingController _controller;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _speech = stt.SpeechToText();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SearchCubit>().search(widget.initialQuery!);
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        if (!mounted) return;
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (!mounted) return;
            _controller.text = val.recognizedWords;
            context.read<SearchCubit>().search(val.recognizedWords);
            setState(() {});
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => BlocProvider.value(
        value: context.read<SearchCubit>(),
        child: const _SearchFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: HealMealTextField(
                  controller: _controller,
                  hint: 'Search medicines or tests',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            context.read<SearchCubit>().search('');
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                        ),
                        color: _isListening
                            ? AppColors.error
                            : AppColors.primary,
                        onPressed: _listen,
                      ),
                    ],
                  ),
                  onChanged: (value) {
                    context.read<SearchCubit>().search(value);
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8.w),
              IconButton.filledTonal(
                onPressed: _showFilterSheet,
                icon: Icon(Icons.filter_list_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.status == SearchStatus.initial) {
                  return ListView(
                    children: [
                      Text('Quick Symptoms', style: AppTextStyles.h3),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  'Fever',
                                  'Headache',
                                  'Cold & Flu',
                                  'Stomach Pain',
                                  'Allergy',
                                  'Diabetes',
                                  'Blood Pressure',
                                  'Vitamin Deficiency',
                                  'Skin Care',
                                  'Eye Care',
                                ]
                                .map(
                                  (e) => ActionChip(
                                    label: Text(e),
                                    onPressed: () {
                                      _controller.text = e;
                                      context.read<SearchCubit>().search(e);
                                      setState(() {});
                                    },
                                    backgroundColor: context.colorSurface,
                                    labelStyle: AppTextStyles.bodySmall,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.pill,
                                    ),
                                    side: BorderSide(
                                      color: context.colorBorder,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      SizedBox(height: 24.h),
                      if (state.recentSearches.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Searches', style: AppTextStyles.h3),
                            TextButton(
                              onPressed: () =>
                                  context.read<SearchCubit>().clearHistory(),
                              child: Text('Clear All'),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.recentSearches
                              .map(
                                (e) => ActionChip(
                                  label: Text(e),
                                  onPressed: () {
                                    _controller.text = e;
                                    context.read<SearchCubit>().search(e);
                                    setState(() {});
                                  },
                                  backgroundColor: context.colorSurface,
                                  labelStyle: AppTextStyles.bodySmall,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.pill,
                                  ),
                                  side: BorderSide(color: context.colorBorder),
                                ),
                              )
                              .toList(),
                        ),
                      ] else ...[
                        SizedBox(height: 32.h),
                        EmptyStateWidget(
                          type: EmptyStateType.search,
                          customTitle: 'Find your medicines and lab tests',
                          customBody: 'Try: Napa, Insulin, CBC...',
                        ),
                      ],
                    ],
                  );
                }

                Widget aiBubble = SizedBox.shrink();
                if (state.aiNote.isNotEmpty) {
                  aiBubble = Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: AppRadius.lg,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Insights',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                state.aiNote,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state.status == SearchStatus.loading) {
                  return Column(
                    children: [
                      aiBubble,
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 260,
                              ),
                          itemCount: 6,
                          itemBuilder: (context, index) =>
                              SkeletonProductCard(),
                        ),
                      ),
                    ],
                  );
                }
                if (state.status == SearchStatus.empty) {
                  return Column(
                    children: [
                      aiBubble,
                      Expanded(
                        child: EmptyStateWidget(
                          type: EmptyStateType.search,
                          customBody:
                              'Try adjusting filters or searching something else.',
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    aiBubble,
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 260,
                        ),
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final product = state.results[index];
                          return ProductCard(
                            product: product,
                            onTap: () => context.push('/product/${product.id}'),
                            onAddToCart: () {
                              context.read<CartCubit>().addItem(product);
                              AppToast.show(
                                context,
                                '${product.drugName} added to cart',
                                type: ToastType.success,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchFilterSheet extends StatelessWidget {
  const _SearchFilterSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTextStyles.h2),
                  TextButton(
                    onPressed: () {
                      context.read<SearchCubit>().updateFilters(
                        SearchFilters(),
                      );
                      context.pop();
                    },
                    child: Text('Reset'),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text('Requires Prescription', style: AppTextStyles.h3),
              SizedBox(height: 12.h),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Yes (Rx)'),
                    selected: state.filters.requiresPrescription == true,
                    onSelected: (v) =>
                        context.read<SearchCubit>().updateFilters(
                          state.filters.copyWith(
                            requiresPrescription: v ? true : null,
                            clearRequiresPrescription: !v,
                          ),
                        ),
                  ),
                  SizedBox(width: 8.w),
                  ChoiceChip(
                    label: Text('No'),
                    selected: state.filters.requiresPrescription == false,
                    onSelected: (v) =>
                        context.read<SearchCubit>().updateFilters(
                          state.filters.copyWith(
                            requiresPrescription: v ? false : null,
                            clearRequiresPrescription: !v,
                          ),
                        ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              HealMealButton(
                label: 'Apply Filters',
                onPressed: () => context.pop(),
                size: ButtonSize.large,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}
