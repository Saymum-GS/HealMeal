import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../core/models.dart';

import '../../core/config.dart';
import '../../core/widgets.dart';
import '../auth/auth_cubit.dart';
import 'lab_cubit.dart';
import '../../core/utils.dart';
import '../../core/repositories.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LabTestHomeScreen extends StatelessWidget {
  const LabTestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(
        title: 'Lab Tests',
        showSearch: true,
        showCart: true,
      ),
      body: BlocBuilder<LabTestCubit, LabTestState>(
        builder: (context, state) {
          if (state.status == LabTestStatus.loading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.status == LabTestStatus.error) {
            return Center(
              child: EmptyStateWidget(
                type: EmptyStateType.error,
                customTitle: 'Failed to load Lab Tests',
                customBody: state.errorMessage ?? 'Please try again later.',
                actionLabel: 'Retry',
                onAction: () => context.read<LabTestCubit>().load(),
              ),
            );
          }

          final tests = state.allTests;
          final packages = state.packages;

          return ListView(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              // Hero Section
              _buildLabHero(context),

              SizedBox(height: AppSpacing.lg),

              if (packages.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Health Packages', style: AppTextStyles.h2),
                      TextButton(
                        onPressed: () => context.push('/labs/packages'),
                        child: Text('View All'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 280.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    itemCount: packages.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      return _LabPackageCard(package: pkg);
                    },
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
              ],

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text('Popular Tests', style: AppTextStyles.h2),
              ),
              SizedBox(height: AppSpacing.md),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 260,
                  ),
                  itemCount: tests.length,
                  itemBuilder: (context, index) {
                    final test = tests[index];
                    return _LabTestCard(test: test);
                  },
                ),
              ),
              SizedBox(height: 40.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabHero(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.xl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home Sample Collection',
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontSize: 22.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Book lab tests from home with fast reports and expert support.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Icon(
            Icons.biotech_rounded,
            color: Colors.white.withOpacity(0.2),
            size: 64.w,
          ),
        ],
      ),
    );
  }
}

class _LabPackageCard extends StatelessWidget {
  const _LabPackageCard({required this.package});
  final LabPackage package;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.colorBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/labs/packages/${package.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: HealMealImage(
                imageUrl: package.imageUrl,
                icon: Icons.science_rounded,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: AppTextStyles.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${package.testIds.length} Tests Included',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (package.mrp > package.salePrice)
                              Text(
                                '৳${package.mrp.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.muted,
                                  fontSize: 10.sp,
                                ),
                              ),
                            Text(
                              '৳${package.salePrice.toStringAsFixed(0)}',
                              style: AppTextStyles.priceSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabTestCard extends StatelessWidget {
  const _LabTestCard({required this.test});
  final LabTest test;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.colorBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/labs/${test.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.8,
              child: HealMealImage(
                imageUrl: test.imageUrl,
                icon: Icons.biotech_rounded,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      style: AppTextStyles.labelMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Report in ${test.reportHours}h',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                        fontSize: 10.sp,
                      ),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (test.mrp > test.salePrice)
                              Text(
                                '৳${test.mrp.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.muted,
                                  fontSize: 10.sp,
                                ),
                              ),
                            Text(
                              '৳${test.salePrice.toStringAsFixed(0)}',
                              style: AppTextStyles.priceSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: AppRadius.sm,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: 16.w,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabTestDetailScreen extends StatelessWidget {
  const LabTestDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final labState = context.watch<LabTestCubit>().state;
    final test = labState.allTests.firstWhereOrNull((item) => item.id == id);

    if (test == null) {
      return Scaffold(
        appBar: HealMealAppBar(title: 'Loading...', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: HealMealAppBar(title: test.name, showBack: true),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: HealMealImage(
              imageUrl: test.imageUrl,
              borderRadius: AppRadius.lg,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(test.name, style: AppTextStyles.h1),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _InfoTag(
                          label: 'Report in ${test.reportHours}h',
                          icon: Icons.timer_outlined,
                        ),
                        SizedBox(width: 8.w),
                        _InfoTag(
                          label: 'Home Sample',
                          icon: Icons.home_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (test.mrp > test.salePrice)
                    Text(
                      '৳${test.mrp.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.muted,
                      ),
                    ),
                  Text(
                    '৳${test.salePrice.toStringAsFixed(0)}',
                    style: AppTextStyles.priceLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32.h),
          Text('Tests Included', style: AppTextStyles.h3),
          SizedBox(height: 12.h),
          ...test.includes.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 20.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(item, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text('Preparation', style: AppTextStyles.h3),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Text(
              test.preparation,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ),
          SizedBox(height: 100.h),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.colorCard,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: HealMealButton(
            label: 'Book Lab Test',
            onPressed: () {
              final isGuest =
                  context.read<AuthCubit>().state is AuthUnauthenticated;
              if (isGuest) {
                showGuestAccountSheet(
                  context,
                  customMessage:
                      'Sign in to book a lab test and view your reports.',
                );
                return;
              }
              context.push('/labs/book/${test.id}');
            },
            size: ButtonSize.large,
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: AppColors.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class LabTestBookingScreen extends StatefulWidget {
  const LabTestBookingScreen({super.key, required this.id});

  final String id;

  @override
  State<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends State<LabTestBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String gender = 'Female';

  // Address
  String? selectedAddressId;

  // Schedule
  DateTime selectedDay = DateTime.now();
  String selectedSlot = 'Morning 7-10';

  // Payment
  String selectedPayment = 'Cash on sample collection';

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final labState = context.watch<LabTestCubit>().state;
    final test = labState.allTests.firstWhereOrNull(
      (item) => item.id == widget.id,
    );
    final package = labState.packages.firstWhereOrNull(
      (item) => item.id == widget.id,
    );

    if (test == null && package == null) {
      return Scaffold(
        appBar: HealMealAppBar(title: 'Loading...', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String itemId = test?.id ?? package!.id;
    final String itemName = test?.name ?? package!.name;
    final double itemPrice = test?.salePrice ?? package!.salePrice;

    final steps = [
      Step(
        title: Text('Patient'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealMealTextField(
                controller: _nameController,
                label: 'Patient Name',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              SizedBox(height: 16.h),
              HealMealTextField(
                controller: _ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age <= 0) return 'Enter a valid age';
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              Row(
                children: ['Male', 'Female', 'Other']
                    .map(
                      (item) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item),
                          selected: gender == item,
                          onSelected: (_) => setState(() => gender = item),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      Step(
        title: Text('Address'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: StreamBuilder<List<Address>>(
          stream: AddressRepository().getUserAddresses(AppSession.userId ?? ''),
          builder: (context, snapshot) {
            final addresses = snapshot.data ?? [];
            if (selectedAddressId == null && addresses.isNotEmpty) {
              selectedAddressId = addresses.first.id;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (addresses.isEmpty) ...[
                  Text(
                    'No delivery addresses found. Please add an address to continue.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: AppSpacing.md),
                ] else ...[
                  ...addresses.map(
                    (a) => RadioListTile<String>(
                      title: Text(a.label),
                      subtitle: Text(a.fullAddress),
                      value: a.id,
                      groupValue: selectedAddressId,
                      onChanged: (val) =>
                          setState(() => selectedAddressId = val),
                      secondary: IconButton(
                        icon: Icon(Icons.edit_location_alt_rounded),
                        onPressed: () =>
                            context.push('/account/addresses/add', extra: a),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
                OutlinedButton.icon(
                  onPressed: () => context.push('/account/addresses/add'),
                  icon: Icon(Icons.add_location_alt_rounded),
                  label: Text('Add New Address'),
                ),
              ],
            );
          },
        ),
      ),
      Step(
        title: Text('Schedule'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 14)),
              focusedDay: selectedDay,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              onDaySelected: (selected, focused) =>
                  setState(() => selectedDay = selected),
              headerStyle: HeaderStyle(formatButtonVisible: false),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text('Time Slot', style: AppTextStyles.labelLarge),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8,
              children: ['Morning 7-10', 'Morning 10-1', 'Afternoon 2-5'].map((
                slot,
              ) {
                final isSelected = selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => selectedSlot = slot);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      Step(
        title: Text('Payment'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        content: Column(
          children:
              [
                    'Cash on sample collection',
                    'Pay at center',
                    'bKash (Manual confirmation available)',
                    'Card (Manual confirmation available)',
                  ]
                  .map(
                    (method) => RadioListTile<String>(
                      title: Text(method),
                      value: method,
                      groupValue: selectedPayment,
                      onChanged: (val) =>
                          setState(() => selectedPayment = val!),
                    ),
                  )
                  .toList(),
        ),
      ),
      Step(
        title: Text('Review'),
        isActive: _currentStep >= 4,
        state: _currentStep == 4 ? StepState.editing : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test: $itemName', style: AppTextStyles.bodyMedium),
            Text(
              'Patient: ${_nameController.text} ($gender, ${_ageController.text}y)',
              style: AppTextStyles.bodyMedium,
            ),
            Text(
              'Date: ${selectedDay.toString().split(' ')[0]} at $selectedSlot',
              style: AppTextStyles.bodyMedium,
            ),
            Text('Payment: $selectedPayment', style: AppTextStyles.bodyMedium),
            SizedBox(height: 16.h),
            Text(
              'Total: ৳${itemPrice.toStringAsFixed(0)}',
              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: HealMealAppBar(title: 'Book Lab Test', showBack: true),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        onStepContinue: () async {
          if (_currentStep == 0) {
            if (!_formKey.currentState!.validate()) return;
          }
          if (_currentStep == 1 && selectedAddressId == null) {
            AppToast.show(
              context,
              'Please select an address',
              type: ToastType.error,
            );
            return;
          }

          if (_currentStep < steps.length - 1) {
            setState(() => _currentStep += 1);
          } else {
            // Final submit
            setState(() => _isLoading = true);
            final userId = AppSession.userId;
            if (userId == null) {
              if (mounted) setState(() => _isLoading = false);
              AppToast.show(
                context,
                'Authentication error. Please sign in again.',
                type: ToastType.error,
              );
              return;
            }

            try {
              final userAddrs = await AddressRepository().getUserAddresses(userId).first;
              final selectedAddr = userAddrs.firstWhere((a) => a.id == selectedAddressId);
              
              final booking = LabBooking(
                id: 'LAB-${DateTime.now().millisecondsSinceEpoch}',
                testId: itemId,
                testName: itemName,
                patientName: _nameController.text.trim(),
                age: _ageController.text.trim(),
                gender: gender,
                selectedDate: selectedDay,
                timeSlot: selectedSlot,
                price: itemPrice,
                createdAt: DateTime.now(),
                userId: userId,
                addressId: selectedAddressId,
                addressText: selectedAddr.fullAddress,
              );

              await LabRepository().createBooking(booking);
              if (context.mounted) context.go('/account/lab-bookings');
            } catch (e) {
              if (mounted) setState(() => _isLoading = false);
              if (context.mounted) {
                AppToast.show(
                  context,
                  'Failed to place booking: $e',
                  type: ToastType.error,
                );
              }
            }
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == steps.length - 1;
          return Padding(
            padding: EdgeInsets.only(top: 16.0.h),
            child: Row(
              children: [
                Expanded(
                  child: HealMealButton(
                    label: isLastStep ? 'Request Booking' : 'Continue',
                    isLoading: _isLoading && isLastStep,
                    onPressed: details.onStepContinue,
                  ),
                ),
                if (_currentStep > 0) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: HealMealButton(
                      label: 'Back',
                      type: ButtonType.text,
                      foregroundColor: AppColors.primary,
                      onPressed: details.onStepCancel,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: steps,
      ),
    );
  }
}
