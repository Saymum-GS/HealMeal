import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class PrescriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPrescription(AppPrescription prescription) async {
    final ref = _firestore.collection('prescriptions').doc();
    final p = prescription.copyWith(id: ref.id);
    await ref.set(p.toMap());
    return ref.id;
  }

  Stream<List<AppPrescription>> getUserPrescriptions(String userId) {
    return _firestore
        .collection('prescriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppPrescription.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> updateStatus(
    String id,
    PrescriptionStatus status,
    String notes,
  ) async {
    await _firestore.collection('prescriptions').doc(id).update({
      'status': status.name,
      'notes': notes,
    });
  }

  Future<void> deletePrescription(String id) async {
    await _firestore.collection('prescriptions').doc(id).delete();
  }
}
