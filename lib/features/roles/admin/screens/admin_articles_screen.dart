import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/models.dart';
import '../../../../core/config.dart';
import '../../../../core/utils.dart';
import '../../../../core/repositories.dart';
import '../../../../core/services.dart';
import '../../../../core/widgets.dart';
import '../cubits/admin_article_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminArticlesScreen extends StatelessWidget {
  const AdminArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminArticleCubit(getIt<ArticleRepository>())..startWatching(),
      child: const _ArticlesView(),
    );
  }
}

Widget _buildSafeImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: AppColors.subtle,
      child: Icon(Icons.image),
    );
  }
  return Image.memory(
    ImageUploadUtil.base64ToImage(url) ?? Uint8List(0),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (c, e, s) => Container(
      width: width,
      height: height,
      color: AppColors.subtle,
      child: Icon(Icons.broken_image),
    ),
  );
}

class _ArticlesView extends StatelessWidget {
  const _ArticlesView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminArticleCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text('Articles (Blog / Tips)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showArticleForm(context, null),
        icon: Icon(Icons.add_rounded),
        label: Text('Add Article'),
      ),
      body: switch (state) {
        AdminArticleInitial() ||
        AdminArticleLoading() => Center(child: CircularProgressIndicator()),
        AdminArticleError(message: final m) => Center(child: Text('Error: $m')),
        AdminArticleLoaded(articles: final articles) =>
          articles.isEmpty
              ? Center(child: Text('No articles found.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.w),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildSafeImage(
                            article.imageUrl,
                            width: 60.w,
                            height: 60.h,
                          ),
                        ),
                        title: Text(
                          article.title,
                          style: AppTextStyles.labelLarge,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${article.category} • ${article.articleType}',
                              style: AppTextStyles.bodySmall,
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: article.status == 'published'
                                        ? AppColors.primary
                                        : AppColors.subtle,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    article.status.toUpperCase(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: article.status == 'published'
                                          ? Colors.white
                                          : AppColors.secondary,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (article.featuredRank > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'RANK: ${article.featuredRank}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showArticleForm(context, article);
                            } else if (value == 'delete') {
                              _confirmDelete(context, article);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: AppColors.accentBlue,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    color: AppColors.error,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        _ => Center(child: Text('Unknown state')),
      },
    );
  }

  void _showArticleForm(BuildContext context, Article? article) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminArticleCubit>(),
        child: _ArticleFormDialog(article: article),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Article article) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Article'),
        content: Text('Are you sure you want to delete "${article.title}"?'),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(ctx),
            label: 'Cancel',
          ),
          HealMealButton(
            type: ButtonType.text,
            foregroundColor: AppColors.error,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AdminArticleCubit>().deleteArticle(article.id);
                if (context.mounted) {
                  AppToast.show(
                    context,
                    'Article deleted',
                    type: ToastType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(
                    context,
                    'Failed to delete article: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
            label: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _ArticleFormDialog extends StatefulWidget {
  final Article? article;
  const _ArticleFormDialog({this.article});
  @override
  _ArticleFormDialogState createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<_ArticleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _readTimeCtrl;
  late TextEditingController _featuredRankCtrl;

  String _articleType = 'article';
  String _status = 'draft';
  String _imageUrl = '';
  bool _isLoading = false;
  late String _articleId;
  DateTime? _publishAt;

  @override
  void initState() {
    super.initState();
    _articleId = widget.article?.id ?? getIt<ArticleRepository>().generateId();
    _titleCtrl = TextEditingController(text: widget.article?.title ?? '');
    _slugCtrl = TextEditingController(text: widget.article?.slug ?? '');
    _summaryCtrl = TextEditingController(text: widget.article?.summary ?? '');
    _bodyCtrl = TextEditingController(text: widget.article?.body ?? '');
    _categoryCtrl = TextEditingController(text: widget.article?.category ?? '');
    _authorCtrl = TextEditingController(
      text: widget.article?.author ?? 'HealMeal Editorial',
    );
    _readTimeCtrl = TextEditingController(
      text: (widget.article?.readTimeMinutes ?? 5).toString(),
    );
    _featuredRankCtrl = TextEditingController(
      text: (widget.article?.featuredRank ?? 0).toString(),
    );

    _articleType = widget.article?.articleType ?? 'article';
    _status = widget.article?.status ?? 'draft';
    _imageUrl = widget.article?.imageUrl ?? '';
    _publishAt = widget.article?.publishAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _summaryCtrl.dispose();
    _bodyCtrl.dispose();
    _categoryCtrl.dispose();
    _authorCtrl.dispose();
    _readTimeCtrl.dispose();
    _featuredRankCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final base64String = await ImageUploadUtil.pickImageAsBase64();
    if (base64String == 'TOO_LARGE') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image exceeds the allowed limit.')),
        );
      }
      return;
    }
    if (base64String != null && mounted) {
      setState(() => _imageUrl = base64String);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        _publishAt = date;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty && _articleType != 'daily_tip') {
      AppToast.show(
        context,
        'Please upload an image for articles',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final article = Article(
        id: _articleId,
        title: _titleCtrl.text.trim(),
        slug: _slugCtrl.text.trim(),
        summary: _summaryCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        imageUrl: _imageUrl,
        articleType: _articleType,
        category: _categoryCtrl.text.trim(),
        relatedProductIds: widget.article?.relatedProductIds ?? [],
        author: _authorCtrl.text.trim(),
        readTimeMinutes: int.tryParse(_readTimeCtrl.text) ?? 5,
        featuredRank: int.tryParse(_featuredRankCtrl.text) ?? 0,
        publishAt: _publishAt ?? DateTime.now(),
        status: _status,
        createdAt: widget.article?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.article == null) {
        await getIt<ArticleRepository>().addArticle(article);
      } else {
        await getIt<ArticleRepository>().updateArticle(article);
      }

      if (mounted) {
        Navigator.pop(context);
        AppToast.show(context, 'Saved successfully', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.article == null
                    ? 'Add Article / Tip'
                    : 'Edit Article / Tip',
                style: AppTextStyles.h2,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HealMealTextField(
                        controller: _titleCtrl,
                        label: 'Title',
                        validator: AppValidators.requiredField,
                        onChanged: (v) {
                          if (widget.article == null) {
                            _slugCtrl.text = v
                                .toLowerCase()
                                .replaceAll(' ', '-')
                                .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
                          }
                        },
                      ),
                      SizedBox(height: 16.h),
                      HealMealTextField(
                        controller: _slugCtrl,
                        label: 'Slug',
                        validator: AppValidators.requiredField,
                      ),
                      SizedBox(height: 16.h),
                      HealMealTextField(
                        controller: _summaryCtrl,
                        label: 'Summary (Short)',
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),
                      HealMealTextField(
                        controller: _bodyCtrl,
                        label: 'Body / Content',
                        maxLines: 5,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _articleType,
                              decoration: InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'article',
                                  child: Text('Full Article'),
                                ),
                                DropdownMenuItem(
                                  value: 'daily_tip',
                                  child: Text('Daily Tip'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _articleType = v!),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'draft',
                                  child: Text('Draft'),
                                ),
                                DropdownMenuItem(
                                  value: 'published',
                                  child: Text('Published'),
                                ),
                                DropdownMenuItem(
                                  value: 'archived',
                                  child: Text('Archived'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: HealMealTextField(
                              controller: _categoryCtrl,
                              label: 'Category',
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: HealMealTextField(
                              controller: _authorCtrl,
                              label: 'Author',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: HealMealTextField(
                              controller: _readTimeCtrl,
                              label: 'Read Time (mins)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: HealMealTextField(
                              controller: _featuredRankCtrl,
                              label: 'Featured Rank (0=No)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Publish Date',
                          style: AppTextStyles.labelSmall,
                        ),
                        subtitle: Text(
                          _publishAt != null
                              ? DateFormat.yMMMd().format(_publishAt!)
                              : 'Not set',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text('Image (Base64)', style: AppTextStyles.labelMedium),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 150.h,
                          decoration: BoxDecoration(
                            color: AppColors.subtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colorBorder),
                          ),
                          child: _imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildSafeImage(
                                    _imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40.w,
                                      color: context.colorTextMuted,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Upload Image',
                                      style: TextStyle(
                                        color: context.colorTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HealMealButton(
                    type: ButtonType.text,
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    label: 'Cancel',
                  ),
                  SizedBox(width: 12.w),
                  HealMealButton(
                    onPressed: _isLoading ? null : _save,
                    isLoading: _isLoading,
                    label: 'Save',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
