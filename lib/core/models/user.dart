import 'package:equatable/equatable.dart';
import 'enums.dart';

abstract class AppUserInterface {
  String get id;
  String get name;
  String get phone;
  String get role;
}

class AppUser extends Equatable implements AppUserInterface {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.photoUrl,
    this.extra = const <String, dynamic>{},

    this.walletBalance = 0.0,
    this.isActive = true,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String role;
  final String? email;
  final String? photoUrl;
  final Map<String, dynamic> extra;

  final double walletBalance;
  final bool isActive;

  factory AppUser.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppUser(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? UserRole.user.name,
      email: map['email'],
      photoUrl: map['photoUrl'],
      extra: Map<String, dynamic>.from(map['extra'] ?? {}),

      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'email': email,
      'photoUrl': photoUrl,
      'extra': extra,

      'walletBalance': walletBalance,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, role, phone];

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? email,
    String? photoUrl,
    Map<String, dynamic>? extra,
    double? walletBalance,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      extra: extra ?? this.extra,
      walletBalance: walletBalance ?? this.walletBalance,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Address extends Equatable {
  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.district,
    required this.upazila,
    required this.area,
    required this.houseFlat,
    required this.roadStreet,
    this.landmark,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String district;
  final String upazila;
  final String area;
  final String houseFlat;
  final String roadStreet;
  final String? landmark;
  final bool isDefault;

  String get fullAddress =>
      '$houseFlat, $roadStreet, $area, $upazila, $district${landmark == null || landmark!.isEmpty ? '' : ' - $landmark'}';

  factory Address.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Address(
      id: docId ?? map['id'] ?? '',
      label: map['label'] ?? '',
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      district: map['district'] ?? '',
      upazila: map['upazila'] ?? '',
      area: map['area'] ?? '',
      houseFlat: map['houseFlat'] ?? '',
      roadStreet: map['roadStreet'] ?? '',
      landmark: map['landmark'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'district': district,
      'upazila': upazila,
      'area': area,
      'houseFlat': houseFlat,
      'roadStreet': roadStreet,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? district,
    String? upazila,
    String? area,
    String? houseFlat,
    String? roadStreet,
    String? landmark,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      district: district ?? this.district,
      upazila: upazila ?? this.upazila,
      area: area ?? this.area,
      houseFlat: houseFlat ?? this.houseFlat,
      roadStreet: roadStreet ?? this.roadStreet,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    label,
    recipientName,
    phoneNumber,
    district,
    upazila,
    area,
  ];
}
