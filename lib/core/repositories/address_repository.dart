import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class AddressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Address>> getUserAddresses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _decodeAddress(doc.data())).toList(),
        );
  }

  Future<void> saveAddress(String userId, Address address) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id.isEmpty ? null : address.id);

    final id = address.id.isEmpty ? ref.id : address.id;

    await ref.set({
      ..._encodeAddress(address),
      'id': id,
    }, SetOptions(merge: true));
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Address _decodeAddress(Map<String, dynamic> data) {
    return Address(
      id: data['id'] ?? '',
      label: data['label'] ?? 'Home',
      recipientName: data['recipientName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      district: data['district'] ?? 'Dhaka',
      upazila: data['upazila'] ?? '',
      area: data['area'] ?? '',
      houseFlat: data['houseFlat'] ?? '',
      roadStreet: data['roadStreet'] ?? '',
      landmark: data['landmark'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> _encodeAddress(Address address) {
    return {
      'id': address.id,
      'label': address.label,
      'recipientName': address.recipientName,
      'phoneNumber': address.phoneNumber,
      'district': address.district,
      'upazila': address.upazila,
      'area': address.area,
      'houseFlat': address.houseFlat,
      'roadStreet': address.roadStreet,
      'landmark': address.landmark,
      'isDefault': address.isDefault,
    };
  }
}
