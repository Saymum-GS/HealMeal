import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus {
  pending('pending', 'In Review'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  final String name;
  final String label;
  const PrescriptionStatus(this.name, this.label);

  static PrescriptionStatus fromString(String? val) {
    if (val == null || val.trim().isEmpty) return PrescriptionStatus.pending;
    return values.firstWhere(
      (e) => e.name.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => PrescriptionStatus.pending,
    );
  }
}

class AppPrescription {
  final String id;
  final String userId;
  final String imageBase64;
  final PrescriptionStatus status;
  final String notes;
  final DateTime createdAt;

  AppPrescription({
    required this.id,
    required this.userId,
    required this.imageBase64,
    this.status = PrescriptionStatus.pending,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageBase64': imageBase64,
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppPrescription.fromMap(Map<String, dynamic> map, String id) {
    return AppPrescription(
      id: id,
      userId: map['userId']?.toString() ?? '',
      imageBase64: map['imageBase64']?.toString() ?? '',
      status: PrescriptionStatus.fromString(map['status']?.toString()),
      notes: map['notes']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AppPrescription copyWith({
    String? id,
    String? userId,
    String? imageBase64,
    PrescriptionStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return AppPrescription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageBase64: imageBase64 ?? this.imageBase64,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
