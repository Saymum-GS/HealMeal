import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/repositories.dart';
import '../../core/services.dart';
import '../../core/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformSettings>(
      future: getIt<SettingsRepository>().getSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: HealMealAppBar(title: 'About HealMeal', showBack: true),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final contact = snapshot.data!.contact;

        return Scaffold(
          appBar: HealMealAppBar(title: 'About HealMeal', showBack: true),
          body: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Center(
                child: Image.asset(
                  AppAssets.logo,
                  height: 80.h,
                  width: 80.w,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.local_hospital_rounded,
                    size: 80.w,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'HealMeal',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Healthcare at your doorstep',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),
              _StaticCard(
                title: 'Our Mission',
                child: Text(
                  'HealMeal exists to make trusted medicine, diagnostics, and healthcare support easier to access across Bangladesh with a calm, reliable digital experience.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              _StaticCard(
                title: 'Our Services',
                child: Column(
                  children: <Widget>[
                    _BulletRow(
                      icon: Icons.medication_outlined,
                      text: 'Medicine delivery',
                    ),
                    _BulletRow(
                      icon: Icons.science_outlined,
                      text: 'Lab test booking',
                    ),
                    _BulletRow(
                      icon: Icons.health_and_safety_outlined,
                      text: 'Healthcare medicines',
                    ),
                    _BulletRow(
                      icon: Icons.description_outlined,
                      text: 'Prescription support',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              _StaticCard(
                title: 'Management',
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            'AR',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(contact.managerName, style: AppTextStyles.h3),
                            Text(
                              contact.managerTitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      label: 'Call',
                      value: contact.phone,
                      onTap: () => _launch(context, contact.phoneUrl),
                    ),
                    _ContactRow(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      value: contact.whatsApp,
                      onTap: () => _launch(context, contact.whatsAppUrl),
                    ),
                    _ContactRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: contact.email,
                      onTap: () => _launch(context, contact.emailUrl),
                    ),
                    _ContactRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: contact.address,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              _StaticCard(
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.verified_user,
                      color: AppColors.primary,
                      size: 40.w,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'LegitScript Certified',
                            style: AppTextStyles.h3,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Bangladesh\'s first LegitScript certified online healthcare platform. All medicines are authentic and sourced from licensed manufacturers.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'HealMeal v1.0.0',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformSettings>(
      future: getIt<SettingsRepository>().getSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: HealMealAppBar(title: 'Contact Us', showBack: true),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final contact = snapshot.data!.contact;

        return Scaffold(
          appBar: HealMealAppBar(title: 'Contact Us', showBack: true),
          body: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              _ContactActionCard(
                icon: Icons.phone_outlined,
                title: contact.phone,
                subtitle: 'Call now',
                actionLabel: 'Call',
                onTap: () => _launch(context, contact.phoneUrl),
              ),
              _ContactActionCard(
                icon: Icons.chat_outlined,
                title: contact.whatsApp,
                subtitle: 'WhatsApp support',
                actionLabel: 'Chat',
                onTap: () => _launch(context, contact.whatsAppUrl),
              ),
              _ContactActionCard(
                icon: Icons.email_outlined,
                title: contact.email,
                subtitle: 'Send an email',
                actionLabel: 'Email',
                onTap: () => _launch(context, contact.emailUrl),
              ),
              _ContactActionCard(
                icon: Icons.location_on_outlined,
                title: contact.address,
                subtitle: 'Visit us',
                actionLabel: 'G Map',
                onTap: () => _launch(
                  context,
                  'https://www.google.com/maps/search/?api=1&query=${contact.address}',
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text('Inquiry Form', style: AppTextStyles.h2),
              SizedBox(height: AppSpacing.md),
              HealMealTextField(controller: _nameController, label: 'Name'),
              SizedBox(height: AppSpacing.lg),
              HealMealTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: AppSpacing.lg),
              HealMealTextField(
                controller: _messageController,
                label: 'Message',
                maxLines: 4,
                minLines: 4,
              ),
              SizedBox(height: AppSpacing.xl),
              HealMealButton(
                label: 'Send Inquiry',
                size: ButtonSize.large,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Inquiry sent successfully')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'Help & FAQ', showBack: true),
      body: StreamBuilder<List<AppFaq>>(
        stream: getIt<FaqRepository>().watchFaqs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final faqs = snapshot.data ?? [];
          final filtered = faqs.where((item) {
            return item.question.toLowerCase().contains(_query.toLowerCase()) ||
                item.answer.toLowerCase().contains(_query.toLowerCase()) ||
                item.category.toLowerCase().contains(_query.toLowerCase());
          }).toList();

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              HealMealTextField(
                controller: _controller,
                label: 'Search FAQs',
                suffixIcon: Icon(Icons.search_rounded),
                onChanged: (String value) => setState(() => _query = value),
              ),
              SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No FAQs found matching your search.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              else
                ...filtered.map((item) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ExpansionTile(
                      backgroundColor: Theme.of(context).cardColor,
                      collapsedBackgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.lg,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: AppRadius.lg,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      title: Text(item.question, style: AppTextStyles.h3),
                      subtitle: Text(
                        item.category,
                        style: AppTextStyles.bodyXSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: Text(
                            item.answer,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class HealthTipsBlogScreen extends StatefulWidget {
  const HealthTipsBlogScreen({super.key});

  @override
  State<HealthTipsBlogScreen> createState() => _HealthTipsBlogScreenState();
}

class _HealthTipsBlogScreenState extends State<HealthTipsBlogScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _category = 'All';
  bool _grid = false;

  @override
  void dispose() {
    _controller.dispose();
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
        title: Text('Health Tips'),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(
              _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Article>>(
        stream: getIt<ArticleRepository>().watchAllArticles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data ?? [];

          final filtered = articles.where((item) {
            final bool matchesCategory =
                _category == 'All' || item.category == _category;
            final bool matchesQuery = item.title.toLowerCase().contains(
              _query.toLowerCase(),
            );
            return matchesCategory && matchesQuery;
          }).toList();

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              HealMealTextField(
                controller: _controller,
                label: 'Search articles',
                suffixIcon: Icon(Icons.search_rounded),
                onChanged: (String value) => setState(() => _query = value),
              ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 42.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      <String>[
                        'All',
                        'Diabetes',
                        'Heart Health',
                        'Nutrition',
                        'Mental Health',
                        'Baby Care',
                        'Skin Care',
                        'Medicine Tips',
                      ].map((String item) {
                        return Padding(
                          padding: EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(item),
                            selected: _category == item,
                            onSelected: (_) => setState(() => _category = item),
                          ),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No articles published yet.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              else if (_grid)
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 320,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (BuildContext context, int index) {
                    final blog = filtered[index];
                    return _BlogCard(
                      blog: blog,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlogDetailScreen(blog: blog),
                        ),
                      ),
                    );
                  },
                )
              else
                ...filtered.map(
                  (blog) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: _BlogCard(
                      blog: blog,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlogDetailScreen(blog: blog),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class BlogDetailScreen extends StatelessWidget {
  const BlogDetailScreen({super.key, required this.blog});

  final Article blog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(blog.category)),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Container(
            height: 200.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.accentBlue],
              ),
              borderRadius: AppRadius.lg,
            ),
            child: Stack(
              children: [
                if (blog.imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: HealMealImage(
                      imageUrl: blog.imageUrl,
                      hasImage: true,
                    ),
                  ),
                if (blog.imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(
                        0.3,
                      ), // Ensure text readability
                    ),
                  ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: Text(
                    blog.title,
                    style: AppTextStyles.h1.copyWith(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            '${blog.author} • ${blog.readTimeMinutes} min read',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            blog.body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformSettings>(
      future: getIt<SettingsRepository>().getSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: HealMealAppBar(
              title: 'Doctor Consultation',
              showBack: true,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final contact = snapshot.data!.contact;

        return Scaffold(
          appBar: HealMealAppBar(title: 'Doctor Consultation', showBack: true),
          body: ListView(
            children: <Widget>[
              Container(
                height: 200.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[AppColors.accentBlue, AppColors.primary],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.medical_services_outlined,
                      size: 64.w,
                      color: AppColors.white,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Doctor Consultation',
                      style: AppTextStyles.displayHero.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Connect with specialist doctors from home',
                      style: AppTextStyles.h2,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Video consultations with licensed Bangladeshi doctors for general medicine, diabetes, cardiac care, gynecology, pediatrics, and more.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final int crossAxisCount =
                                constraints.maxWidth < 380 ? 1 : 2;
                            const features =
                                <({IconData icon, String title, String body})>[
                                  (
                                    icon: Icons.video_call_outlined,
                                    title: 'Video Call',
                                    body: 'HD consultation from your phone',
                                  ),
                                  (
                                    icon: Icons.schedule_rounded,
                                    title: 'Available 24/7',
                                    body: 'Day and night doctor access',
                                  ),
                                  (
                                    icon: Icons.description_outlined,
                                    title: 'E-Prescription',
                                    body:
                                        'Digital prescription after consultation',
                                  ),
                                  (
                                    icon: Icons.shield_outlined,
                                    title: 'Licensed Doctors',
                                    body: 'BMDC registered doctors only',
                                  ),
                                ];
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: AppSpacing.md,
                                    crossAxisSpacing: AppSpacing.md,
                                    mainAxisExtent: crossAxisCount == 1
                                        ? 124
                                        : 140,
                                  ),
                              itemCount: features.length,
                              itemBuilder: (BuildContext context, int index) {
                                final feature = features[index];
                                return _FeatureTile(
                                  icon: feature.icon,
                                  title: feature.title,
                                  body: feature.body,
                                );
                              },
                            );
                          },
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Row(
                      children: <Widget>[
                        Expanded(child: SizedBox.shrink()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'Get Notified',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Be the first to know when this launches.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    HealMealTextField(
                      controller: _phoneController,
                      label: 'Your Phone Number',
                      hint: '01XXXXXXXXX',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    HealMealButton(
                      label: 'Notify Me When Available',
                      size: ButtonSize.large,
                      isLoading: _loading,
                      onPressed: () async {
                        setState(() => _loading = true);
                        await Future<void>.delayed(Duration(seconds: 1));
                        if (!context.mounted) return;
                        setState(() => _loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You will be notified when Doctor Consultation launches!',
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Color(0xFF25D366).withOpacity(.1),
                        borderRadius: AppRadius.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Need urgent consultation now?',
                            style: AppTextStyles.h3,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Contact our health team on WhatsApp.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          HealMealButton(
                            label: 'WhatsApp: ${contact.whatsApp}',
                            type: ButtonType.outlined,
                            size: ButtonSize.medium,
                            onPressed: () =>
                                _launch(context, contact.whatsAppUrl),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CareersScreen extends StatelessWidget {
  const CareersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const jobs = <String>[
      'Delivery Rider|Full Time|Logistics|Dhaka|Support fast and safe AppOrder delivery across the city.',
      'Pharmacist|Full Time|Healthcare|Tejgaon|Review prescriptions and support medicine operations.',
      'Customer Support Executive|Full Time|Support|Remote|Help customers with ordering, tracking, and medicine questions.',
      'Flutter Developer (Mobile)|Full Time|Tech|Remote/Tejgaon|Build polished, scalable mobile experiences for healthcare users.',
    ];
    return FutureBuilder<PlatformSettings>(
      future: getIt<SettingsRepository>().getSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: HealMealAppBar(title: 'We Are Hiring', showBack: true),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final contact = snapshot.data!.contact;

        return Scaffold(
          appBar: HealMealAppBar(title: 'We Are Hiring', showBack: true),
          body: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Container(
                height: 180.h,
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Join the HealMeal Team',
                      style: AppTextStyles.displayHero.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      contact.address,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text('Open Positions', style: AppTextStyles.h2),
              SizedBox(height: AppSpacing.md),
              ...jobs.map((row) {
                final parts = row.split('|');
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: AppRadius.lg,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(parts[0], style: AppTextStyles.h2),
                      SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: <Widget>[
                          _JobBadge(label: parts[1], color: AppColors.primary),
                          _JobBadge(
                            label: parts[2],
                            color: AppColors.accentBlue,
                          ),
                          _JobBadge(
                            label: parts[3],
                            color: AppColors.accentOrange,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        parts[4],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Apply Now'),
                                  content: Text(
                                    'Send your CV to ${contact.email}',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text('Apply Now'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Don\'t see your role?', style: AppTextStyles.h3),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => _launch(context, contact.emailUrl),
                      child: Text(
                        contact.email,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Contact: ${contact.phone}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PolicyScaffold(
      title: 'Privacy Policy',
      sections: <String>[
        'HealMeal respects your privacy and only uses account, order, and device information required to provide a safe healthcare shopping experience.',
        'Prescription images, profile details, initialAddresses, and AppOrder history are displayed in this demo as mock frontend data and are not sent to a backend.',
        'When backend services are connected, HealMeal should store medical and personal data using secure transport, role-based access, and audit-friendly controls.',
        'Users can review saved initialAddresses, notifications, language choice, and theme preference within the account section of the app.',
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PolicyScaffold(
      title: 'Terms & Conditions',
      sections: <String>[
        'HealMeal provides a digital interface for browsing medicines, lab tests, and healthcare items.',
        'Medicines marked as prescription-only require valid prescription handling before checkout can proceed.',
        'Delivery windows, availability, and discounts shown are illustrative and may vary based on location and inventory.',
        'Users should verify medical guidance with licensed professionals before consuming medicines or acting on health content shown in the app.',
      ],
    );
  }
}

class ReturnPolicyScreen extends StatelessWidget {
  const ReturnPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PolicyScaffold(
      title: 'Return Policy',
      sections: <String>[
        'Return requests should be raised quickly if damaged, incorrect, or incomplete items are delivered.',
        'Temperature-sensitive medicines and certain medical items may be non-returnable unless quality issues are verified.',
        'Customers may be asked for AppOrder details, photos, and medicine packaging information to review a claim.',
        'Refund timing depends on payment method and fulfillment review once backend payment flows are connected.',
      ],
    );
  }
}

class _PolicyScaffold extends StatelessWidget {
  const _PolicyScaffold({required this.title, required this.sections});

  final String title;
  final List<String> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: title, showBack: true),
      body: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.lg),
        itemCount: sections.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppRadius.lg,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              sections[index],
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaticCard extends StatelessWidget {
  const _StaticCard({this.title, required this.child});

  final String? title;
  final Widget child;

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
          if (title != null) ...<Widget>[
            Text(title!, style: AppTextStyles.h3),
            SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 20.w),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.primary),
            SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 84.w,
              child: Text(label, style: AppTextStyles.labelLarge),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  const _ContactActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.h3),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110.w,
            child: HealMealButton(
              label: actionLabel,
              size: ButtonSize.small,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.blog, required this.onTap});

  final Article blog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppRadius.lg,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 140.h,
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[AppColors.primary, AppColors.accentBlue],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      blog.category,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Spacer(),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        '${blog.readTimeMinutes} min read',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '${blog.author} • ${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    blog.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Read More →',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primary),
          SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.h3),
          SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _JobBadge extends StatelessWidget {
  const _JobBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

Future<void> _launch(BuildContext context, String value) async {
  try {
    await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open link')));
    }
  }
}
