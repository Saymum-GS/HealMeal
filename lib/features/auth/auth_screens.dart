import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../core/localization.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';
import '../../core/models.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectUrl});

  final String? redirectUrl;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppToast.show(context, state.message, type: ToastType.error);
        }
        if (state is AuthAuthenticated) {
          context.read<CartCubit>().reloadAndMigrate();
          Future.microtask(() {
            if (!context.mounted) return;
            if (state.role.homeRoute == '/admin') {
              context.go('/admin');
            } else if (widget.redirectUrl != null &&
                widget.redirectUrl!.isNotEmpty) {
              final decodedUrl = Uri.decodeComponent(widget.redirectUrl!);
              context.go(decodedUrl);
            } else {
              context.go(state.role.homeRoute);
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: HealMealAppBar(
            title: '',
            showBack: false,
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
          body: AppLayout.constrained(
            context: context,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      size: 64.w,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      context.strings.login,
                      style: AppTextStyles.displayHero,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      context.tr('Sign in to continue', 'এগিয়ে যেতে লগইন করুন'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48.h),
                    HealMealTextField(
                      controller: _emailController,
                      label: context.tr(
                        'Email or Phone Number',
                        'ইমেইল বা ফোন নম্বর',
                      ),
                      hint: '017... or name@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.required,
                      prefix: Icon(Icons.person_outline),
                    ),
                    SizedBox(height: 16.h),
                    HealMealTextField(
                      controller: _passwordController,
                      label: context.tr('Password', 'পাসওয়ার্ড'),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthCubit>().signIn(
                            _emailController.text.trim(),
                            _passwordController.text,
                          );
                        }
                      },
                      validator: AppValidators.required,
                      prefix: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          context.tr(
                            'Forgot Password?',
                            'পাসওয়ার্ড ভুলে গেছেন?',
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    HealMealButton(
                      label: context.strings.login,
                      size: ButtonSize.large,
                      isLoading: state is AuthLoading,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthCubit>().signIn(
                            _emailController.text.trim(),
                            _passwordController.text,
                          );
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        context.tr(
                          "Don't have an account? Register here",
                          "অ্যাকাউন্ট নেই? এখানে নিবন্ধন করুন",
                        ),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Expanded(child: SizedBox.shrink()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            context.tr('or', 'অথবা'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.colorTextMuted,
                            ),
                          ),
                        ),
                        Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    HealMealButton(
                      label: context.strings.orderViaWhatsApp,
                      type: ButtonType.outlined,
                      prefixIcon: Icons.chat,
                      onPressed: () =>
                          launchUrl(Uri.parse('https://wa.me/8801325188042')),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      context.tr(
                        'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
                        'চালিয়ে গেলে আপনি আমাদের শর্তাবলী ও প্রাইভেসি পলিসিতে সম্মত হচ্ছেন।',
                      ),
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: context.colorTextMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppToast.show(context, state.message, type: ToastType.error);
        }
        if (state is AuthAuthenticated) {
          context.read<CartCubit>().reloadAndMigrate();
          Future.microtask(() {
            if (context.mounted) context.go(state.role.homeRoute);
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: HealMealAppBar(title: '', showBack: true),
          body: AppLayout.constrained(
            context: context,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 64.w,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      'Create Account',
                      style: AppTextStyles.displayHero,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Join our healthcare network',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48.h),
                    HealMealTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      validator: AppValidators.required,
                      prefix: Icon(Icons.person_outline),
                    ),
                    SizedBox(height: 16.h),
                    HealMealTextField(
                      controller: _phoneController,
                      label: 'Phone Number (Optional if Email given)',
                      hint: '01712345678',
                      keyboardType: TextInputType.phone,
                      prefix: Icon(Icons.phone_outlined),
                    ),
                    SizedBox(height: 16.h),
                    HealMealTextField(
                      controller: _emailController,
                      label: 'Email Address (Optional if Phone given)',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if ((val == null || val.trim().isEmpty) && _phoneController.text.trim().isEmpty) {
                          return 'Provide Email or Phone';
                        }
                        return null;
                      },
                      prefix: Icon(Icons.email_outlined),
                    ),
                    SizedBox(height: 16.h),
                    HealMealTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: _obscurePassword,
                      validator: (val) => val != null && val.length < 6
                          ? 'Minimum 6 characters'
                          : null,
                      prefix: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    HealMealTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: _obscurePassword,
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      prefix: Icon(Icons.lock_outline),
                    ),
                    SizedBox(height: 48.h),
                    HealMealButton(
                      label: "Sign Up",
                      size: ButtonSize.large,
                      isLoading: state is AuthLoading,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          if (_emailController.text.trim().isEmpty && _phoneController.text.trim().isEmpty) {
                            AppToast.show(context, 'Please enter either a Phone Number or Email Address', type: ToastType.error);
                            return;
                          }
                          final identifier = _emailController.text.trim().isNotEmpty
                              ? _emailController.text.trim()
                              : _phoneController.text.trim();
                          context.read<AuthCubit>().signUp(
                            identifier,
                            _passwordController.text,
                            _nameController.text.trim(),
                            UserRole.user,
                            phone: _phoneController.text.trim(),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          "Already have an account? Log In",
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -- Forgot Password Screen (ISSUE-003) -------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          AppToast.show(
            context,
            context.tr(
              'Reset link sent! Check your email.',
              'রিসেট লিংক পাঠানো হয়েছে!',
            ),
            type: ToastType.success,
          );
          context.pop();
        }
        if (state is AuthError) {
          AppToast.show(context, state.message, type: ToastType.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: HealMealAppBar(
            title: context.tr('Reset Password', 'পাসওয়ার্ড রিসেট'),
            showBack: true,
          ),
          body: AppLayout.constrained(
            context: context,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    Text(
                      context.tr(
                        'Enter your email address and we will send you a link to reset your password.',
                        'আপনার ইমেইল দিন, আমরা পাসওয়ার্ড রিসেটের লিংক পাঠাবো।',
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorTextSecondary,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    HealMealTextField(
                      controller: _emailController,
                      label: context.tr('Email Address', 'ইমেইল ঠিকানা'),
                      hint: 'your.name@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: AppValidators.required,
                      prefix: Icon(Icons.email_outlined),
                    ),
                    SizedBox(height: 24.h),
                    HealMealButton(
                      label: context.tr('Send Reset Link', 'রিসেট লিংক পাঠান'),
                      size: ButtonSize.large,
                      isLoading: state is AuthLoading,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthCubit>().sendPasswordResetEmail(
                            _emailController.text,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
