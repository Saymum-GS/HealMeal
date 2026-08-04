import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminFaqScreen extends StatelessWidget {
  const AdminFaqScreen({super.key});

  void _showAddEditDialog(BuildContext context, [AppFaq? faq]) {
    final questionController = TextEditingController(text: faq?.question);
    final answerController = TextEditingController(text: faq?.answer);
    final categoryController = TextEditingController(
      text: faq?.category ?? 'General',
    );
    final orderController = TextEditingController(
      text: faq?.order.toString() ?? '0',
    );
    String status = faq?.status ?? 'published';
    final isEdit = faq != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit FAQ' : 'Add FAQ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HealMealTextField(
                  controller: categoryController,
                  label: 'Category (e.g. Orders)',
                ),
                SizedBox(height: 16.h),
                HealMealTextField(
                  controller: questionController,
                  label: 'Question',
                ),
                SizedBox(height: 16.h),
                HealMealTextField(
                  controller: answerController,
                  label: 'Answer',
                  maxLines: 4,
                ),
                SizedBox(height: 16.h),
                HealMealTextField(
                  controller: orderController,
                  label: 'Sort Order',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(labelText: 'Status'),
                  items: [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'published',
                      child: Text('Published'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) status = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            HealMealButton(
              type: ButtonType.text,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            HealMealButton(
              onPressed: () async {
                final q = questionController.text.trim();
                final a = answerController.text.trim();
                final cat = categoryController.text.trim();
                final ord = int.tryParse(orderController.text.trim()) ?? 0;

                if (q.isEmpty || a.isEmpty || cat.isEmpty) {
                  AppToast.show(
                    context,
                    'Please fill all required fields.',
                    type: ToastType.info,
                  );
                  return;
                }

                final docRef = isEdit
                    ? FirebaseFirestore.instance.collection('faqs').doc(faq.id)
                    : FirebaseFirestore.instance.collection('faqs').doc();

                final data = {
                  'question': q,
                  'answer': a,
                  'category': cat,
                  'order': ord,
                  'status': status,
                };
                if (!isEdit) {
                  data['createdAt'] = FieldValue.serverTimestamp();
                }

                try {
                  await docRef.set(data, SetOptions(merge: true));
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppToast.show(context, 'FAQ Saved.', type: ToastType.success);
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(context, 'Error saving FAQ: $e', type: ToastType.error);
                  }
                }
              },
              label: 'Save',
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'FAQ Management', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: Icon(Icons.add_rounded),
        label: Text('Add FAQ'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faqs')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text('No FAQs yet. Tap + to add one.'));
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              100,
            ),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final faq = AppFaq.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return Card(
                child: ListTile(
                  title: Text(faq.question, style: AppTextStyles.labelMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq.answer,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Category: ${faq.category} - Order: ${faq.order}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colorTextMuted,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showAddEditDialog(context, faq);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Delete FAQ?'),
                            content: Text('This cannot be undone.'),
                            actions: [
                              HealMealButton(
                                type: ButtonType.text,
                                onPressed: () => Navigator.pop(context, false),
                                label: 'Cancel',
                              ),
                              HealMealButton(
                                backgroundColor: AppColors.error,
                                onPressed: () => Navigator.pop(context, true),
                                label: 'Delete',
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('faqs')
                                .doc(faq.id)
                                .delete();
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                'FAQ Deleted.',
                                type: ToastType.success,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                'Failed to delete FAQ: $e',
                                type: ToastType.error,
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
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
                              Icons.delete_outline,
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
          );
        },
      ),
    );
  }
}
