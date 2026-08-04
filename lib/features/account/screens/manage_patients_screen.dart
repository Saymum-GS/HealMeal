import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../../../core/widgets.dart';

class ManagePatientsScreen extends StatefulWidget {
  const ManagePatientsScreen({super.key});

  @override
  State<ManagePatientsScreen> createState() => _ManagePatientsScreenState();
}

class _ManagePatientsScreenState extends State<ManagePatientsScreen> {
  late List<PatientData> _patients;

  @override
  void initState() {
    super.initState();
    _patients =
        []; // Initialize as empty. Real data should come from Firestore in the future.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text('Manage Patients'),
        actions: <Widget>[
          IconButton(
            onPressed: _openAddPatientSheet,
            icon: Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatientSheet,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          InfoBanner(
            title: 'Patient profiles',
            body:
                'Save patient profiles to quickly book lab tests for family members.',
            type: InfoBannerType.info,
          ),
          SizedBox(height: AppSpacing.lg),
          ..._patients.map((patient) {
            final String initials = patient.name
                .split(' ')
                .where((part) => part.isNotEmpty)
                .take(2)
                .map((part) => part[0])
                .join();
            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: AppRadius.lg,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: <Widget>[
                            Text(patient.name, style: AppTextStyles.h3),
                            if (patient.isSelf || patient.relation.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.pill,
                                ),
                                child: Text(
                                  patient.relation,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '${patient.age} years - ${patient.gender}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openAddPatientSheet,
                    icon: Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _patients.remove(patient)),
                    icon: Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openAddPatientSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ageController = TextEditingController();
    String gender = 'Male';
    String relation = 'Self';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Add Patient', style: AppTextStyles.h2),
                  SizedBox(height: AppSpacing.lg),
                  HealMealTextField(
                    controller: nameController,
                    label: 'Full Name',
                  ),
                  SizedBox(height: AppSpacing.md),
                  HealMealTextField(
                    controller: ageController,
                    label: 'Age',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text('Gender', style: AppTextStyles.labelLarge),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: <String>['Male', 'Female', 'Other']
                        .map(
                          (String item) => ChoiceChip(
                            label: Text(item),
                            selected: gender == item,
                            onSelected: (_) =>
                                setModalState(() => gender = item),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text('Relation', style: AppTextStyles.labelLarge),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children:
                        <String>[
                              'Self',
                              'Spouse',
                              'Parent',
                              'Child',
                              'Sibling',
                              'Other',
                            ]
                            .map(
                              (String item) => ChoiceChip(
                                label: Text(item),
                                selected: relation == item,
                                onSelected: (_) =>
                                    setModalState(() => relation = item),
                              ),
                            )
                            .toList(),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  HealMealButton(
                    label: 'Save Patient',
                    size: ButtonSize.large,
                    onPressed: () {
                      setState(() {
                        _patients = <PatientData>[
                          ..._patients,
                          PatientData(
                            name: nameController.text.trim().isEmpty
                                ? 'New Patient'
                                : nameController.text.trim(),
                            age: int.tryParse(ageController.text) ?? 30,
                            gender: gender,
                            relation: relation,
                            isSelf: relation == 'Self',
                          ),
                        ];
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PatientData {
  PatientData({
    required this.name,
    required this.age,
    required this.gender,
    required this.relation,
    this.isSelf = false,
  });

  final String name;
  final int age;
  final String gender;
  final String relation;
  final bool isSelf;
}
