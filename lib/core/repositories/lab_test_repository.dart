import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class LabTestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LabTest>> fetchLabTests() async {
    final snapshot = await _firestore.collection('lab_tests').get();

    if (snapshot.docs.isEmpty) {
      try {
        await _seedDefaultLabTests();
      } catch (e) {
        // Will fail for non-admins due to firestore rules, which is expected.
      }
      final retrySnapshot = await _firestore.collection('lab_tests').get();
      return retrySnapshot.docs
          .where((doc) => !doc.id.startsWith('lab_'))
          .map((doc) => _decodeLabTest(doc.data()))
          .toList();
    }

    return snapshot.docs
        .where((doc) => !doc.id.startsWith('lab_'))
        .map((doc) => _decodeLabTest(doc.data()))
        .toList();
  }

  Future<List<LabPackage>> fetchLabPackages() async {
    final snapshot = await _firestore.collection('lab_packages').get();

    if (snapshot.docs.isEmpty) {
      return [
        LabPackage(
          id: 'pkg-diabetes',
          name: 'Diabetes Screening',
          description: 'Includes FBS, HbA1c, Lipid Profile',
          testIds: ['lab_fbs', 'lab_hba1c', 'lab_lipid'],
          mrp: 1500,
          salePrice: 1200,
          imageUrl: '',
        ),
        LabPackage(
          id: 'pkg-anemia',
          name: 'Anemia Check',
          description: 'Includes CBC, Iron Studies',
          testIds: ['lab_cbc', 'lab_iron'],
          mrp: 1200,
          salePrice: 999,
          imageUrl: '',
        ),
      ];
    }

    return snapshot.docs
        .map((doc) => LabPackage.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<LabTest>> watchLabTests() {
    return _firestore
        .collection('lab_tests')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => !doc.id.startsWith('lab_'))
              .map(
                (doc) =>
                    _decodeLabTest(doc.data()..putIfAbsent('id', () => doc.id)),
              )
              .toList(),
        );
  }

  Stream<List<LabPackage>> watchLabPackages() {
    return _firestore
        .collection('lab_packages')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => LabPackage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  String generateId() => _firestore.collection('lab_tests').doc().id;

  Future<void> addLabTest(Map<String, dynamic> data) async {
    final String id = data['id'] ?? _firestore.collection('lab_tests').doc().id;
    final docRef = _firestore.collection('lab_tests').doc(id);
    data['id'] = id;
    await docRef.set(data);
  }

  Future<void> updateLabTest(String id, Map<String, dynamic> data) async {
    await _firestore.collection('lab_tests').doc(id).update(data);
  }

  Future<void> deleteLabTest(String id) async {
    await _firestore.collection('lab_tests').doc(id).delete();
  }

  String generatePackageId() => _firestore.collection('lab_packages').doc().id;

  Future<void> addLabPackage(LabPackage package) async {
    await _firestore
        .collection('lab_packages')
        .doc(package.id)
        .set(package.toMap());
  }

  Future<void> updateLabPackage(LabPackage package) async {
    await _firestore
        .collection('lab_packages')
        .doc(package.id)
        .update(package.toMap());
  }

  Future<void> deleteLabPackage(String id) async {
    await _firestore.collection('lab_packages').doc(id).delete();
  }

  Future<void> _seedDefaultLabTests() async {
    final defaultTests = [
      {
        'id': 'lab-full-body',
        'name': 'Full Body Health Checkup',
        'slug': 'full-body',
        'mrp': 3500.0,
        'salePrice': 2499.0,
        'discountPercent': 28,
        'reportHours': '24',
        'preparation': '10-12 hours fasting required.',
        'imageUrl':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=', // tiny transparent pixel or use a real placeholder if needed
        'includes': [
          'CBC',
          'Lipid Profile',
          'Liver Function Test',
          'Kidney Function Test',
          'Thyroid Profile',
        ],
      },
      {
        'id': 'lab-diabetes',
        'name': 'Comprehensive Diabetes Care',
        'slug': 'diabetes-care',
        'mrp': 1800.0,
        'salePrice': 999.0,
        'discountPercent': 44,
        'reportHours': '12',
        'preparation':
            '10-12 hours fasting required. Bring morning urine sample.',
        'imageUrl':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
        'includes': [
          'Fasting Blood Sugar',
          'HbA1c',
          'Lipid Profile',
          'Urine Routine',
        ],
      },
      {
        'id': 'lab-cardiac',
        'name': 'Cardiac Risk Assessment',
        'slug': 'cardiac-risk',
        'mrp': 2200.0,
        'salePrice': 1499.0,
        'discountPercent': 31,
        'reportHours': '24',
        'preparation': '10-12 hours fasting required.',
        'imageUrl':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
        'includes': ['ECG', 'Lipid Profile', 'hs-CRP', 'Homocysteine'],
      },
      {
        'id': 'lab-fever',
        'name': 'Fever Panel (Basic)',
        'slug': 'fever-panel',
        'mrp': 1200.0,
        'salePrice': 799.0,
        'discountPercent': 33,
        'reportHours': '12',
        'preparation': 'No special preparation required.',
        'imageUrl':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
        'includes': ['CBC', 'Dengue NS1', 'Malaria Parasite', 'Widal Test'],
      },
    ];

    for (final test in defaultTests) {
      await _firestore
          .collection('lab_tests')
          .doc(test['id'] as String)
          .set(test);
    }
  }

  LabTest _decodeLabTest(Map<String, dynamic> data) {
    return LabTest(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      mrp: (data['mrp'] ?? 0.0).toDouble(),
      salePrice: (data['salePrice'] ?? 0.0).toDouble(),
      discountPercent: data['discountPercent'] ?? 0,
      reportHours: (data['reportHours'] ?? 24).toString(),
      preparation: data['preparation'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      includes: List<String>.from(data['includes'] ?? []),
    );
  }
}
