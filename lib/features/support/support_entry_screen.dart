import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets.dart';
import '../../core/config.dart';
import '../../core/services.dart';
import '../../core/repositories.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SupportEntryScreen extends StatefulWidget {
  const SupportEntryScreen({super.key});

  @override
  State<SupportEntryScreen> createState() => _SupportEntryScreenState();
}

class _SupportEntryScreenState extends State<SupportEntryScreen> {
  ContactSettings? _contact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await getIt<SettingsRepository>().getSettings();
    if (mounted) {
      setState(() {
        _contact = settings.contact;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppToast.show(
            context,
            'App not installed or link unsupported',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Could not open link', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Help & Support', showBack: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(AppSpacing.lg),
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 80.w,
                  color: AppColors.primary,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'How can we help you?',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Our support team is available during business hours:\n${_contact?.businessHours ?? ''}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colorTextMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                _SupportOption(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp Support',
                  subtitle: 'Chat with us instantly',
                  color: Color(0xFF25D366),
                  onTap: () => _launchUrl(_contact?.whatsAppUrl ?? ''),
                ),
                SizedBox(height: AppSpacing.md),
                _SupportOption(
                  icon: Icons.phone_rounded,
                  title: 'Call Us',
                  subtitle: _contact?.phone ?? '',
                  color: AppColors.accentBlue,
                  onTap: () => _launchUrl(_contact?.phoneUrl ?? ''),
                ),
                SizedBox(height: AppSpacing.md),
                _SupportOption(
                  icon: Icons.email_rounded,
                  title: 'Email Us',
                  subtitle: _contact?.email ?? '',
                  color: AppColors.primary,
                  onTap: () => _launchUrl(_contact?.emailUrl ?? ''),
                ),
                SizedBox(height: AppSpacing.xl),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg.topLeft.x),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Office Address', style: AppTextStyles.labelLarge),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        _contact?.address ?? '',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lg,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.lg,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28.w),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.colorTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colorTextMuted),
          ],
        ),
      ),
    );
  }
}
