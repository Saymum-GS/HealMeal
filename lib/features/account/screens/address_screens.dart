import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

List<String> districts = <String>[
  'Bagerhat',
  'Bandarban',
  'Barguna',
  'Barishal',
  'Bhola',
  'Bogura',
  'Brahmanbaria',
  'Chandpur',
  'Chattogram',
  'Cumilla',
  'Dhaka',
  'Dinajpur',
  'Faridpur',
  'Gazipur',
  'Gopalganj',
  'Jamalpur',
  'Jashore',
  'Khulna',
  'Kishoreganj',
  'Kurigram',
  'Madaripur',
  'Manikganj',
  'Moulvibazar',
  'Munshiganj',
  'Mymensingh',
  'Naogaon',
  'Narayanganj',
  'Narsingdi',
  'Noakhali',
  'Pabna',
  'Rajshahi',
  'Rangpur',
  'Satkhira',
  'Shariatpur',
  'Sherpur',
  'Sirajganj',
  'Sylhet',
  'Tangail',
];

Map<String, List<String>> upazilasByDistrict = <String, List<String>>{
  'Dhaka': <String>['Dhanmondi', 'Tejgaon', 'Mirpur', 'Uttara', 'Mohammadpur'],
  'Gazipur': <String>['Tongi', 'Sreepur', 'Kaliakair', 'Gazipur Sadar'],
  'Chattogram': <String>['Pahartali', 'Panchlaish', 'Kotwali', 'Halishahar'],
  'Cumilla': <String>['Cumilla Sadar', 'Daudkandi', 'Laksam', 'Burichang'],
  'Rajshahi': <String>['Boalia', 'Motihar', 'Paba', 'Godagari'],
  'Khulna': <String>['Khalishpur', 'Sonadanga', 'Dumuria', 'Rupsha'],
};

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final AddressRepository _repository = AddressRepository();

  @override
  Widget build(BuildContext context) {
    final userId = AppSession.userId;
    if (userId == null) {
      return Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      appBar: HealMealAppBar(title: 'Delivery Addresses', showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/account/addresses/add'),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<List<Address>>(
        stream: _repository.getUserAddresses(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data ?? [];

          if (addresses.isEmpty) {
            return Center(child: Text('No addresses saved yet.'));
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final Address address = addresses[index];
              return Dismissible(
                key: Key(address.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.lg,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: AppSpacing.lg),
                  child: Icon(Icons.edit_outlined, color: AppColors.primary),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: AppRadius.lg,
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: AppSpacing.lg),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
                confirmDismiss: (DismissDirection direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    return false;
                  }
                  return showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) => ConfirmDialog(
                      title: 'Delete Address',
                      body:
                          'Remove ${address.label} from your saved addresses?',
                      confirmLabel: 'Delete',
                      isDangerous: true,
                    ),
                  );
                },
                onDismissed: (_) async {
                  try {
                    await _repository.deleteAddress(userId, address.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete address: $e')));
                    }
                  }
                },
                child: _AddressCard(address: address),
              );
            },
          );
        },
      ),
    );
  }
}

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _roadController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  String _district = 'Dhaka';
  String _upazila = 'Tejgaon';
  bool _isDefault = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final a = widget.address!;
      _nameController.text = a.recipientName; // Using recipientName
      _phoneController.text = a.phoneNumber;
      _areaController.text = a.area;
      _houseController.text = a.houseFlat;
      _roadController.text = a.roadStreet;
      _landmarkController.text = a.landmark ?? '';
      _district = a.district;
      _upazila = a.upazila;
      _isDefault = a.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _houseController.dispose();
    _roadController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> upazilas =
        upazilasByDistrict[_district] ?? <String>['Sadar'];
    if (!upazilas.contains(_upazila)) {
      _upazila = upazilas.first;
    }
    return Scaffold(
      appBar: HealMealAppBar(
        title: widget.address == null ? 'Add New Address' : 'Edit Address',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            HealMealTextField(
              controller: _nameController,
              label: 'Recipient Name',
              validator: (String? value) =>
                  value == null || value.trim().length < 2
                  ? 'Recipient name is required'
                  : null,
            ),
            SizedBox(height: AppSpacing.lg),
            HealMealTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefix: Icon(Icons.phone_android_rounded),
              validator: (String? value) => value == null || value.length < 11
                  ? 'Enter valid phone number'
                  : null,
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'District',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _district,
                        isExpanded: true,
                        items: districts
                            .map(
                              (String d) => DropdownMenuItem<String>(
                                value: d,
                                child: Text(d),
                              ),
                            )
                            .toList(),
                        onChanged: (String? val) {
                          if (val != null) setState(() => _district = val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Area / Upazila',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _upazila,
                        isExpanded: true,
                        items: upazilas
                            .map(
                              (String u) => DropdownMenuItem<String>(
                                value: u,
                                child: Text(u),
                              ),
                            )
                            .toList(),
                        onChanged: (String? val) {
                          if (val != null) setState(() => _upazila = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            HealMealTextField(
              controller: _areaController,
              label: 'Area / Locality',
              hint: 'e.g. Sector 4, Block D',
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: HealMealTextField(
                    controller: _houseController,
                    label: 'House / Flat',
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HealMealTextField(
                    controller: _roadController,
                    label: 'Road / Street',
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            HealMealTextField(
              controller: _landmarkController,
              label: 'Landmark (Optional)',
              hint: 'e.g. Near Central Mosque',
            ),
            SizedBox(height: AppSpacing.xl),
            SwitchListTile(
              title: Text('Set as Default Address'),
              value: _isDefault,
              onChanged: (bool val) => setState(() => _isDefault = val),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: AppSpacing.xl),
            HealMealButton(
              label: 'Save Address',
              size: ButtonSize.large,
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = AppSession.userId;
    if (userId == null) return;

    setState(() => _isSaving = true);
    final Address newAddress = Address(
      id:
          widget.address?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label: 'Home',
      recipientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      district: _district,
      upazila: _upazila,
      area: _areaController.text.trim(),
      houseFlat: _houseController.text.trim(),
      roadStreet: _roadController.text.trim(),
      landmark: _landmarkController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      await AddressRepository().saveAddress(AppSession.userId!, newAddress);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppToast.show(context, 'Error: $e', type: ToastType.error);
      }
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                address.label == 'Home'
                    ? Icons.home_outlined
                    : Icons.work_outline_rounded,
                color: AppColors.primary,
                size: 20.w,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(address.label, style: AppTextStyles.labelLarge),
              Spacer(),
              if (address.isDefault)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'Default',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(address.recipientName, style: AppTextStyles.h3),
          Text(address.phoneNumber, style: AppTextStyles.bodySmall),
          SizedBox(height: AppSpacing.xs),
          Text(
            '${address.houseFlat}, ${address.roadStreet}, ${address.area}, ${address.upazila}, ${address.district}',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
