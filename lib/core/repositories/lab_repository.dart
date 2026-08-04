import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class LabRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking(LabBooking booking) async {
    await _firestore.runTransaction((tx) async {
      double serverPrice = 0.0;

      final testRef = _firestore.collection('lab_tests').doc(booking.testId);
      final testSnap = await tx.get(testRef);

      if (testSnap.exists) {
        serverPrice = (testSnap.data()?['salePrice'] as num? ?? 0.0).toDouble();
      } else {
        final pkgRef = _firestore
            .collection('lab_packages')
            .doc(booking.testId);
        final pkgSnap = await tx.get(pkgRef);
        if (pkgSnap.exists) {
          serverPrice = (pkgSnap.data()?['salePrice'] as num? ?? 0.0)
              .toDouble();
        } else {
          throw Exception('Lab test or package not found.');
        }
      }

      final bookingRef = _firestore.collection('lab_bookings').doc(booking.id);
      final secureBooking = booking.copyWith(price: serverPrice);

      tx.set(bookingRef, secureBooking.toMap());
    });
  }

  Stream<List<LabBooking>> watchBookings() {
    return _firestore
        .collection('lab_bookings')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LabBooking.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<LabBooking>> watchUserBookings(String userId) {
    return _firestore
        .collection('lab_bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LabBooking.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> updateBookingStatus(String id, LabBookingStatus status) async {
    await _firestore.collection('lab_bookings').doc(id).update({
      'status': status.name,
    });
  }

  Future<void> attachReport(String id, String reportUrl) async {
    await _firestore.collection('lab_bookings').doc(id).update({
      'reportUrl': reportUrl,
      'status': LabBookingStatus.completed.name,
    });
  }

  Future<void> updateAdvancedBookingFields(
    String bookingId, {
    String? reportBase64,
    String? assignedSlot,
    String? cancellationReason,
    LabBookingStatus? status,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reportBase64 != null) updates['reportBase64'] = reportBase64;
    if (assignedSlot != null) updates['assignedSlot'] = assignedSlot;
    if (cancellationReason != null) {
      updates['cancellationReason'] = cancellationReason;
    }
    if (status != null) updates['status'] = status.name;
    await _firestore.collection('lab_bookings').doc(bookingId).update(updates);
  }
}
