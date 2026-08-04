import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import '../../auth/auth_cubit.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _gender = '';
  String _bloodGroup = '';
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    String name = '';
    String phone = '';
    String email = '';
    String dob = '';
    String height = '';
    String weight = '';
    if (authState is AuthAuthenticated) {
      name = authState.name ?? '';
      phone = authState.phone ?? '';
      email = authState.email ?? '';
      _photoUrl = authState.photoUrl;
      if (authState.dob != null && authState.dob!.isNotEmpty) {
        dob = authState.dob!;
      }
      if (authState.gender != null && authState.gender!.isNotEmpty) {
        _gender = authState.gender!;
      }
      if (authState.bloodGroup != null && authState.bloodGroup!.isNotEmpty) {
        _bloodGroup = authState.bloodGroup!;
      }
      height = authState.height ?? '';
      weight = authState.weight ?? '';
    }
    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _emailController = TextEditingController(text: email);
    _dobController = TextEditingController(text: dob);
    _heightController = TextEditingController(text: height);
    _weightController = TextEditingController(text: weight);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text('Edit Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                Center(
                  child: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage:
                            _photoUrl != null && _photoUrl!.isNotEmpty
                            ? ImageBase64Util.resolveProvider(_photoUrl!)
                            : null,
                        child: _photoUrl == null || _photoUrl!.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                size: 38.w,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () async {
                            final String? base64 =
                                await ImageUploadUtil.pickImageAsBase64();
                            if (base64 == null) return;
                            if (base64 == 'TOO_LARGE') {
                              if (context.mounted) {
                                AppToast.show(
                                  context,
                                  'Image exceeds 900KB limit for Firestore.',
                                  type: ToastType.error,
                                );
                              }
                              return;
                            }
                            setState(() {
                              _photoUrl = base64;
                            });
                          },
                          child: Container(
                            width: 32.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.white,
                              size: 18.w,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                HealMealTextField(controller: _nameController, label: 'Name'),
                SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      initialDate: DateTime(1991, 8, 12),
                    );
                    if (picked != null) {
                      _dobController.text = AppFormatters.shortDate(picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: HealMealTextField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: <String>['Male', 'Female', 'Other']
                      .map(
                        (String gender) => ChoiceChip(
                          label: Text(gender),
                          selected: _gender == gender,
                          onSelected: (_) => setState(() => _gender = gender),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: AppSpacing.lg),
                HealMealTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: AppSpacing.lg),
                HealMealTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: HealMealTextField(
                        controller: _heightController,
                        label: "Height (e.g. 5'8\")",
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: HealMealTextField(
                        controller: _weightController,
                        label: 'Weight (e.g. 70kg)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Blood Group',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children:
                      <String>['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map(
                            (String bg) => ChoiceChip(
                              label: Text(bg),
                              selected: _bloodGroup == bg,
                              onSelected: (_) =>
                                  setState(() => _bloodGroup = bg),
                            ),
                          )
                          .toList(),
                ),
                SizedBox(height: AppSpacing.xl),
                HealMealButton(
                  label: 'Update Profile',
                  size: ButtonSize.large,
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final userId = AppSession.userId;
    if (userId == null) return;

    final authState = context.read<AuthCubit>().state;
    setState(() => _isLoading = true);
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await userDoc.set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'dob': _dobController.text,
        'gender': _gender,
        'bloodGroup': _bloodGroup,
        'height': _heightController.text,
        'weight': _weightController.text,
        'photoUrl': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_phoneController.text.trim().isNotEmpty) {
        try {
          final cleanPhone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
          String currentEmail = _emailController.text.trim();
          if (currentEmail.isEmpty && authState is AuthAuthenticated) {
            currentEmail = authState.email ?? '';
          }
          await FirebaseFirestore.instance.collection('phone_directory').doc(cleanPhone).set({
            'email': currentEmail.isNotEmpty ? currentEmail : '$cleanPhone@phone.healmeal.app',
            'userId': userId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      if (mounted) {
        await context.read<AuthCubit>().restoreSession();
        if (mounted) {
          AppToast.show(
            context,
            'Profile updated successfully!',
            type: ToastType.success,
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show(context, 'Failed to update: $e', type: ToastType.error);
      }
    }
  }
}
