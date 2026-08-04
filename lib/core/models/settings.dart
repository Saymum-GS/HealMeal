import 'package:equatable/equatable.dart';

class PlatformSettings extends Equatable {
  final double deliveryCharge;
  final double freeDeliveryThreshold;
  final double cashbackPercentage;
  final double maxCashbackAmount;
  final double taxRate;
  final ContactSettings contact;
  final List<ServiceShortcut> serviceShortcuts;
  final HomeLayoutConfig homeLayout;

  const PlatformSettings({
    required this.deliveryCharge,
    required this.freeDeliveryThreshold,
    required this.cashbackPercentage,
    required this.maxCashbackAmount,
    required this.taxRate,
    this.contact = const ContactSettings(),
    this.serviceShortcuts = const [],
    this.homeLayout = const HomeLayoutConfig(),
  });

  factory PlatformSettings.fromMap(Map<String, dynamic> map) {
    return PlatformSettings(
      deliveryCharge: (map['deliveryCharge'] ?? 80.0).toDouble(),
      freeDeliveryThreshold: (map['freeDeliveryThreshold'] ?? 1999.0).toDouble(),
      cashbackPercentage: (map['cashbackPercentage'] ?? 8.0).toDouble(),
      maxCashbackAmount: (map['maxCashbackAmount'] ?? 125.5).toDouble(),
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      contact: ContactSettings.fromMap(
        map['contact'] as Map<String, dynamic>? ?? {},
      ),
      serviceShortcuts:
          (map['serviceShortcuts'] as List<dynamic>?)
              ?.map((e) => ServiceShortcut.fromMap(e as Map<String, dynamic>))
              .toList() ??
          ServiceShortcut.defaults,
      homeLayout: HomeLayoutConfig.fromMap(
        map['homeLayout'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryCharge': deliveryCharge,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'cashbackPercentage': cashbackPercentage,
      'maxCashbackAmount': maxCashbackAmount,
      'taxRate': taxRate,
      'contact': contact.toMap(),
      'serviceShortcuts': serviceShortcuts.map((s) => s.toMap()).toList(),
      'homeLayout': homeLayout.toMap(),
    };
  }

  factory PlatformSettings.defaultSettings() {
    return PlatformSettings(
      deliveryCharge: 80.0,
      freeDeliveryThreshold: 1999.0,
      cashbackPercentage: 8.0,
      maxCashbackAmount: 125.5,
      taxRate: 0.0,
      contact: ContactSettings(),
      serviceShortcuts: ServiceShortcut.defaults,
      homeLayout: HomeLayoutConfig(),
    );
  }

  PlatformSettings copyWith({
    double? deliveryCharge,
    double? freeDeliveryThreshold,
    double? cashbackPercentage,
    double? maxCashbackAmount,
    double? taxRate,
    ContactSettings? contact,
    List<ServiceShortcut>? serviceShortcuts,
    HomeLayoutConfig? homeLayout,
  }) {
    return PlatformSettings(
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      cashbackPercentage: cashbackPercentage ?? this.cashbackPercentage,
      maxCashbackAmount: maxCashbackAmount ?? this.maxCashbackAmount,
      taxRate: taxRate ?? this.taxRate,
      contact: contact ?? this.contact,
      serviceShortcuts: serviceShortcuts ?? this.serviceShortcuts,
      homeLayout: homeLayout ?? this.homeLayout,
    );
  }

  @override
  List<Object?> get props => [
    deliveryCharge,
    freeDeliveryThreshold,
    cashbackPercentage,
    maxCashbackAmount,
    taxRate,
    contact,
    serviceShortcuts,
    homeLayout,
  ];
}

/// Contact information - replaces all hardcoded phone/email/address across screens.
class ContactSettings extends Equatable {
  final String phone;
  final String whatsApp;
  final String email;
  final String address;
  final String managerName;
  final String managerTitle;
  final String businessHours;
  final bool isEnabled;

  const ContactSettings({
    this.phone = '01325188042',
    this.whatsApp = '8801325188042',
    this.email = 'arifahsan690@gmail.com',
    this.address =
        '45 No Polytechnic Mosjid Market, Tejgaon Industrial Area, Dhaka-1208',
    this.managerName = 'Md Arifur Rahman',
    this.managerTitle = 'Manager & CEO',
    this.businessHours = 'Sat–Thu, 9 AM – 10 PM',
    this.isEnabled = true,
  });

  String get whatsAppUrl => 'https://wa.me/$whatsApp';
  String get phoneUrl => 'tel:$phone';
  String get emailUrl => 'mailto:$email';

  factory ContactSettings.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return ContactSettings();
    return ContactSettings(
      phone: map['phone'] ?? '01325188042',
      whatsApp: map['whatsApp'] ?? '8801325188042',
      email: map['email'] ?? 'arifahsan690@gmail.com',
      address:
          map['address'] ??
          '45 No Polytechnic Mosjid Market, Tejgaon Industrial Area, Dhaka-1208',
      managerName: map['managerName'] ?? 'Md Arifur Rahman',
      managerTitle: map['managerTitle'] ?? 'Manager & CEO',
      businessHours: map['businessHours'] ?? 'Sat–Thu, 9 AM – 10 PM',
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'whatsApp': whatsApp,
      'email': email,
      'address': address,
      'managerName': managerName,
      'managerTitle': managerTitle,
      'businessHours': businessHours,
      'isEnabled': isEnabled,
    };
  }

  @override
  List<Object?> get props => [
    phone,
    whatsApp,
    email,
    address,
    managerName,
    managerTitle,
    businessHours,
    isEnabled,
  ];
}

/// Quick action / service shortcut shown on home screen.
class ServiceShortcut extends Equatable {
  final String id;
  final String label;
  final String subtitle;
  final String iconKey;
  final String route;
  final String badgeText;
  final bool isPublished;
  final int sortOrder;

  const ServiceShortcut({
    required this.id,
    required this.label,
    this.subtitle = '',
    required this.iconKey,
    required this.route,
    this.badgeText = '',
    this.isPublished = true,
    this.sortOrder = 0,
  });

  factory ServiceShortcut.fromMap(Map<String, dynamic> map) {
    return ServiceShortcut(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      subtitle: map['subtitle'] ?? '',
      iconKey: map['iconKey'] ?? 'medication',
      route: map['route'] ?? '/products',
      badgeText: map['badgeText'] ?? '',
      isPublished: map['isPublished'] ?? true,
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'subtitle': subtitle,
      'iconKey': iconKey,
      'route': route,
      'badgeText': badgeText,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
    };
  }

  static List<ServiceShortcut> get defaults => [
    ServiceShortcut(
      id: 'medicines',
      label: 'Medicines',
      subtitle: 'Order now',
      iconKey: 'medication',
      route: '/products',
      sortOrder: 0,
    ),
    ServiceShortcut(
      id: 'prescription',
      label: 'Upload Rx',
      subtitle: '10% off',
      iconKey: 'upload_file',
      route: '/prescriptions/upload',
      sortOrder: 1,
    ),
    ServiceShortcut(
      id: 'lab_test',
      label: 'Lab Test',
      subtitle: 'Book now',
      iconKey: 'science',
      route: '/labs',
      sortOrder: 2,
    ),
    ServiceShortcut(
      id: 'health_deals',
      label: 'Health Deals',
      subtitle: 'Save more',
      iconKey: 'favorite',
      route: '/products?featured=true',
      sortOrder: 3,
    ),
  ];

  @override
  List<Object?> get props => [
    id,
    label,
    subtitle,
    iconKey,
    route,
    badgeText,
    isPublished,
    sortOrder,
  ];
}

/// Controls which home sections are visible and their order.
class HomeLayoutConfig extends Equatable {
  final List<HomeSectionConfig> sections;

  const HomeLayoutConfig({this.sections = const []});

  factory HomeLayoutConfig.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return HomeLayoutConfig(sections: HomeSectionConfig.defaults);
    }
    final list =
        (map['sections'] as List<dynamic>?)
            ?.map((e) => HomeSectionConfig.fromMap(e as Map<String, dynamic>))
            .toList() ??
        HomeSectionConfig.defaults;
    return HomeLayoutConfig(sections: list);
  }

  Map<String, dynamic> toMap() {
    return {'sections': sections.map((s) => s.toMap()).toList()};
  }

  /// Get enabled sections sorted by sortOrder.
  List<HomeSectionConfig> get enabledSections =>
      sections.where((s) => s.isEnabled).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  List<Object?> get props => [sections];
}

/// Configuration for a single home screen section.
class HomeSectionConfig extends Equatable {
  /// Unique key: 'hero_banners', 'services', 'collections', 'reorder',
  /// 'deals', 'featured', 'lab_packages', 'articles', 'trust_strip'
  final String key;
  final String title;
  final bool isEnabled;
  final int sortOrder;

  const HomeSectionConfig({
    required this.key,
    this.title = '',
    this.isEnabled = true,
    this.sortOrder = 0,
  });

  factory HomeSectionConfig.fromMap(Map<String, dynamic> map) {
    return HomeSectionConfig(
      key: map['key'] ?? '',
      title: map['title'] ?? '',
      isEnabled: map['isEnabled'] ?? true,
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'title': title,
      'isEnabled': isEnabled,
      'sortOrder': sortOrder,
    };
  }

  static List<HomeSectionConfig> get defaults => [
    HomeSectionConfig(key: 'search_hero', title: 'Search Hero', sortOrder: 0),
    HomeSectionConfig(key: 'action_grid', title: 'Action Grid', sortOrder: 1),
    HomeSectionConfig(
      key: 'prescription_strip',
      title: 'Upload Prescription Strip',
      sortOrder: 2,
    ),
    HomeSectionConfig(key: 'reorder', title: 'Buy Again', sortOrder: 3),
    HomeSectionConfig(
      key: 'diabetes_care',
      title: 'Diabetes care',
      sortOrder: 4,
    ),
    HomeSectionConfig(
      key: 'heart_care',
      title: 'Heart & blood pressure',
      sortOrder: 5,
    ),
    HomeSectionConfig(key: 'deals', title: 'Deals & Offers', sortOrder: 6),
    HomeSectionConfig(key: 'lab_packages', title: 'Lab Tests', sortOrder: 7),
    HomeSectionConfig(key: 'under_100', title: 'Under ৳100', sortOrder: 8),
    HomeSectionConfig(key: 'skin_care', title: 'Skin care', sortOrder: 9),
    HomeSectionConfig(
      key: 'vitamin_care',
      title: 'Vitamins & supplements',
      sortOrder: 10,
    ),
    HomeSectionConfig(
      key: 'trust_strip',
      title: 'Trust & Support',
      sortOrder: 11,
    ),
    HomeSectionConfig(key: 'articles', title: 'Health Content', sortOrder: 12),
  ];

  @override
  List<Object?> get props => [key, title, isEnabled, sortOrder];
}
