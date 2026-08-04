import 'package:equatable/equatable.dart';
import 'enums.dart';

class LabTest extends Equatable {
  const LabTest({
    required this.id,
    required this.name,
    required this.slug,
    required this.includes,
    required this.mrp,
    required this.salePrice,
    required this.discountPercent,
    required this.reportHours,
    required this.preparation,
    required this.imageUrl,
    this.isAvailable = true,
    this.isPopular = false,
    this.isHomeCollection = true,
    this.category = 'General',
    this.createdAt,
  });

  factory LabTest.fromMap(Map<String, dynamic> map, [String? docId]) {
    return LabTest(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      includes: List<String>.from(map['includes'] ?? []),
      mrp: (map['mrp'] ?? 0.0).toDouble(),
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
      discountPercent: (map['discountPercent'] ?? 0).toInt(),
      reportHours: map['reportHours'] ?? '',
      preparation: map['preparation'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isPopular: map['isPopular'] ?? false,
      isHomeCollection: map['isHomeCollection'] ?? true,
      category: map['category'] ?? 'General',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'includes': includes,
      'mrp': mrp,
      'salePrice': salePrice,
      'discountPercent': discountPercent,
      'reportHours': reportHours,
      'preparation': preparation,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'isHomeCollection': isHomeCollection,
      'category': category,
      'createdAt': createdAt,
    };
  }

  final String id;
  final String name;
  final String slug;
  final List<String> includes;
  final double mrp;
  final double salePrice;
  final int discountPercent;
  final String reportHours;
  final String preparation;
  final String imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final bool isHomeCollection;
  final String category;
  final DateTime? createdAt;

  @override
  List<Object?> get props => <Object?>[id, name];
}

class LabPackage extends Equatable {
  const LabPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.testIds,
    required this.mrp,
    required this.salePrice,
    required this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final List<String> testIds;
  final double mrp;
  final double salePrice;
  final String imageUrl;
  final bool isActive;

  factory LabPackage.fromMap(Map<String, dynamic> map, [String? docId]) {
    return LabPackage(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      testIds: List<String>.from(map['testIds'] ?? []),
      mrp: (map['mrp'] ?? 0.0).toDouble(),
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'testIds': testIds,
      'mrp': mrp,
      'salePrice': salePrice,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class LabBooking extends Equatable {
  final String id;
  final String testId;
  final String testName;
  final String patientName;
  final String age;
  final String gender;
  final DateTime selectedDate;
  final String timeSlot;
  final LabBookingStatus status;
  final double price;
  final DateTime createdAt;
  final String userId;
  final String? reportUrl;
  final String? reportBase64;
  final String? assignedSlot;
  final String? cancellationReason;
  final String? addressId;
  final String? addressText;

  const LabBooking({
    required this.id,
    required this.testId,
    required this.testName,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.selectedDate,
    required this.timeSlot,
    this.status = LabBookingStatus.upcoming,
    required this.price,
    required this.createdAt,
    required this.userId,
    this.reportUrl,
    this.reportBase64,
    this.assignedSlot,
    this.cancellationReason,
    this.addressId,
    this.addressText,
  });

  factory LabBooking.fromMap(Map<String, dynamic> map, [String? docId]) {
    return LabBooking(
      id: docId ?? map['id'] ?? '',
      testId: map['testId'] ?? '',
      testName: map['testName'] ?? '',
      patientName: map['patientName'] ?? '',
      age: map['age'] ?? '',
      gender: map['gender'] ?? '',
      selectedDate: map['selectedDate'] is DateTime
          ? map['selectedDate']
          : (map['selectedDate'] != null
                ? (map['selectedDate'] as dynamic).toDate()
                : DateTime.now()),
      timeSlot: map['timeSlot'] ?? '',
      status: LabBookingStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? ''),
        orElse: () => LabBookingStatus.upcoming,
      ),
      price: (map['price'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : (map['createdAt'] != null
                ? (map['createdAt'] as dynamic).toDate()
                : DateTime.now()),
      userId: map['userId'] ?? '',
      reportUrl: map['reportUrl'],
      reportBase64: map['reportBase64'],
      assignedSlot: map['assignedSlot'],
      cancellationReason: map['cancellationReason'],
      addressId: map['addressId'],
      addressText: map['addressText'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'testName': testName,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'selectedDate': selectedDate,
      'timeSlot': timeSlot,
      'status': status.name,
      'price': price,
      'createdAt': createdAt,
      'userId': userId,
      'reportUrl': reportUrl,
      'reportBase64': reportBase64,
      'assignedSlot': assignedSlot,
      'cancellationReason': cancellationReason,
      'addressId': addressId,
      'addressText': addressText,
    };
  }

  LabBooking copyWith({
    String? id,
    String? testId,
    String? testName,
    String? patientName,
    String? age,
    String? gender,
    DateTime? selectedDate,
    String? timeSlot,
    LabBookingStatus? status,
    double? price,
    DateTime? createdAt,
    String? userId,
    String? reportUrl,
    String? reportBase64,
    String? assignedSlot,
    String? cancellationReason,
    String? addressId,
    String? addressText,
  }) {
    return LabBooking(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      selectedDate: selectedDate ?? this.selectedDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      reportUrl: reportUrl ?? this.reportUrl,
      reportBase64: reportBase64 ?? this.reportBase64,
      assignedSlot: assignedSlot ?? this.assignedSlot,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      addressId: addressId ?? this.addressId,
      addressText: addressText ?? this.addressText,
    );
  }

  @override
  List<Object?> get props => [id, testName, patientName, status];
}
