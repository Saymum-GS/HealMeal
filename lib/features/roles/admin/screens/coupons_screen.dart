import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/config.dart';
import '../../../../../core/widgets.dart';
import '../../../../../core/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showCouponDialog([DocumentSnapshot? doc]) {
    final isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic> : null;

    final codeController = TextEditingController(text: data?['code'] ?? '');
    final discountController = TextEditingController(
      text: (data?['discountPercent'] ?? '').toString(),
    );
    bool isActive = data?['isActive'] ?? true;
    final minSpendController = TextEditingController(
      text: (data?['minimumSpend'] ?? 0).toString(),
    );
    final maxUsesController = TextEditingController(
      text: (data?['maxUses'] ?? 0).toString(),
    );
    final audienceController = TextEditingController(
      text: data?['audience'] ?? '',
    );
    DateTime? startDate = data?['startDate'] != null
        ? (data?['startDate'] as Timestamp).toDate()
        : null;
    DateTime? expirationDate = data?['expirationDate'] != null
        ? (data?['expirationDate'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Coupon' : 'New Coupon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HealMealTextField(
                  controller: codeController,
                  label: 'Coupon Code (e.g. SAVE20)',
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: AppSpacing.md),
                HealMealTextField(
                  controller: discountController,
                  label: 'Discount Percent (e.g. 20)',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: AppSpacing.md),
                HealMealTextField(
                  controller: minSpendController,
                  label: 'Minimum Spend (\$)',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: AppSpacing.md),
                HealMealTextField(
                  controller: maxUsesController,
                  label: 'Max Uses (0 for unlimited)',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: AppSpacing.md),
                HealMealTextField(
                  controller: audienceController,
                  label: 'Audience (e.g. all, new_users)',
                ),
                SizedBox(height: AppSpacing.md),
                ListTile(
                  title: Text('Start Date'),
                  subtitle: Text(
                    startDate == null
                        ? 'Immediate'
                        : startDate!.toLocal().toString().split(' ')[0],
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  title: Text('Expiration Date'),
                  subtitle: Text(
                    expirationDate == null
                        ? 'Never'
                        : expirationDate!.toLocal().toString().split(' ')[0],
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          expirationDate ??
                          DateTime.now().add(Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => expirationDate = date);
                    }
                  },
                ),
                SwitchListTile(
                  title: Text('Is Active'),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
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
                final code = codeController.text.trim().toUpperCase();
                final discount =
                    double.tryParse(discountController.text) ?? 0.0;
                final minSpend =
                    double.tryParse(minSpendController.text) ?? 0.0;
                final maxUses = int.tryParse(maxUsesController.text) ?? 0;

                if (code.isEmpty || discount <= 0 || discount > 100) {
                  AppToast.show(
                    context,
                    'Invalid code or discount value.',
                    type: ToastType.error,
                  );
                  return;
                }

                final payload = <String, dynamic>{
                  'code': code,
                  'discountPercent': discount,
                  'minimumSpend': minSpend,
                  'maxUses': maxUses,
                  'audience': audienceController.text.trim(),
                  'isActive': isActive,
                  'timesUsed': isEditing ? (data?['timesUsed'] ?? 0) : 0,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (startDate != null) {
                  payload['startDate'] = Timestamp.fromDate(startDate!);
                } else {
                  payload['startDate'] = null;
                }

                if (expirationDate != null) {
                  payload['expirationDate'] = Timestamp.fromDate(
                    expirationDate!,
                  );
                } else {
                  payload['expirationDate'] = null;
                }

                try {
                  if (isEditing) {
                    await _firestore
                        .collection('coupons')
                        .doc(doc.id)
                        .update(payload);
                  } else {
                    payload['createdAt'] = FieldValue.serverTimestamp();
                    await _firestore.collection('coupons').add(payload);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppToast.show(
                      context,
                      isEditing ? 'Coupon updated!' : 'Coupon created!',
                      type: ToastType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      'Error saving coupon: $e',
                      type: ToastType.error,
                    );
                  }
                }
              },
              label: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCoupon(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Coupon'),
        content: Text('Are you sure you want to delete this coupon?'),
        actions: [
          HealMealButton(
            type: ButtonType.text,
            onPressed: () => Navigator.pop(context),
            label: 'Cancel',
          ),
          HealMealButton(
            backgroundColor: AppColors.error,
            onPressed: () async {
              try {
                await _firestore.collection('coupons').doc(id).delete();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  AppToast.show(
                    context,
                    'Error deleting coupon: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(
        title: 'Manage Coupons',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showCouponDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('coupons')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text('No coupons found. Add one.'));
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.md,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                tileColor: Theme.of(context).cardColor,
                title: Text(data['code'] ?? '', style: AppTextStyles.h3),
                subtitle: Text(
                  'Discount: ${data['discountPercent']}% - Status: ${data['isActive'] == true ? 'Active' : 'Inactive'}',
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showCouponDialog(doc);
                    } else if (value == 'delete') {
                      _deleteCoupon(doc.id);
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
              );
            },
          );
        },
      ),
    );
  }
}
