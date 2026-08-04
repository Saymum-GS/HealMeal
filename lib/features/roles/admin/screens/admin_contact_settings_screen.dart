import 'package:flutter/material.dart';
import '../../../../core/config.dart';
import '../../../../core/models.dart';
import '../../../../core/services.dart';
import '../../../../core/repositories.dart';
import '../../../../core/widgets.dart';
import '../../../../core/utils.dart';

class AdminContactSettingsScreen extends StatefulWidget {
  const AdminContactSettingsScreen({super.key});
  @override
  State<AdminContactSettingsScreen> createState() =>
      _AdminContactSettingsScreenState();
}

class _AdminContactSettingsScreenState
    extends State<AdminContactSettingsScreen> {
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _managerTitleCtrl = TextEditingController();
  final _businessHoursCtrl = TextEditingController();
  bool _isLoading = false;
  PlatformSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await getIt<SettingsRepository>().getSettings();
    setState(() {
      _phoneCtrl.text = _settings?.contact.phone ?? '';
      _whatsappCtrl.text = _settings?.contact.whatsApp ?? '';
      _emailCtrl.text = _settings?.contact.email ?? '';
      _addressCtrl.text = _settings?.contact.address ?? '';
      _managerNameCtrl.text = _settings?.contact.managerName ?? '';
      _managerTitleCtrl.text = _settings?.contact.managerTitle ?? '';
      _businessHoursCtrl.text = _settings?.contact.businessHours ?? '';
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    setState(() => _isLoading = true);
    try {
      final updatedContact = ContactSettings(
        phone: _phoneCtrl.text,
        whatsApp: _whatsappCtrl.text,
        email: _emailCtrl.text,
        address: _addressCtrl.text,
        managerName: _managerNameCtrl.text,
        managerTitle: _managerTitleCtrl.text,
        businessHours: _businessHoursCtrl.text,
      );
      await getIt<SettingsRepository>().updateSettings(
        _settings!.copyWith(contact: updatedContact),
      );
      if (mounted) AppToast.show(context, 'Contact Settings saved', type: ToastType.success);
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error saving contact settings: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: HealMealAppBar(title: 'Contact Settings', showBack: true),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          HealMealTextField(controller: _phoneCtrl, label: 'Phone Number'),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _whatsappCtrl,
            label: 'WhatsApp Number',
          ),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(controller: _emailCtrl, label: 'Email'),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(controller: _addressCtrl, label: 'Address'),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _managerNameCtrl,
            label: 'Manager Name',
          ),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _managerTitleCtrl,
            label: 'Manager Title',
          ),
          SizedBox(height: AppSpacing.md),
          HealMealTextField(
            controller: _businessHoursCtrl,
            label: 'Business Hours',
          ),
          SizedBox(height: AppSpacing.xl),
          HealMealButton(
            label: 'Save Settings',
            onPressed: _saveSettings,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
