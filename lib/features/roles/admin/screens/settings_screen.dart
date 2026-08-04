import 'package:flutter/material.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/services.dart';
import '../../../../core/repositories.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _deliveryController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _cashbackController = TextEditingController();
  final _maxCashbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await getIt<SettingsRepository>().getSettings();
    setState(() {
      _deliveryController.text = settings.deliveryCharge.toString();
      _thresholdController.text = settings.freeDeliveryThreshold.toString();
      _cashbackController.text = settings.cashbackPercentage.toString();
      _maxCashbackController.text = settings.maxCashbackAmount.toString();
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = PlatformSettings(
        deliveryCharge: double.tryParse(_deliveryController.text) ?? 60.0,
        freeDeliveryThreshold:
            double.tryParse(_thresholdController.text) ?? 500.0,
        cashbackPercentage: double.tryParse(_cashbackController.text) ?? 8.0,
        maxCashbackAmount:
            double.tryParse(_maxCashbackController.text) ?? 125.5,
        taxRate: 0.0,
      );
      await getIt<SettingsRepository>().updateSettings(settings);
      if (mounted) {
        AppToast.show(
          context,
          'Settings saved successfully.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error saving settings: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Global Settings', showBack: true),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          HealMealTextField(
            controller: _deliveryController,
            label: 'Delivery Charge (৳)',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _thresholdController,
            label: 'Free Delivery Threshold (৳)',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _cashbackController,
            label: 'Cashback Percentage (%)',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _maxCashbackController,
            label: 'Max Cashback Amount (৳)',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 32.h),
          Text('Platform Sections', style: AppTextStyles.h3),
          SizedBox(height: AppSpacing.md),
          /*
          ListTile(
            leading: Icon(Icons.contact_phone_rounded),
            title: Text('Contact Settings'),
            subtitle: Text(
              'Manage support phone, WhatsApp, email, and address',
            ),
            trailing: Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/admin/contact-settings'),
          ),
          ListTile(
            leading: Icon(Icons.apps_rounded),
            title: Text('Service Shortcuts'),
            subtitle: Text('Manage home screen quick action tiles'),
            trailing: Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/admin/service-shortcuts'),
          ),
          */
          SizedBox(height: AppSpacing.xl),
          HealMealButton(
            label: 'Save Global Settings',
            onPressed: _saveSettings,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
