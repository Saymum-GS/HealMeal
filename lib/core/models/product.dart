import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/product_tokenizer.dart';

// -- Enums --------------------------------------------------------------------

enum DosageForm {
  tablet,
  capsule,
  syrup,
  suspension,
  injection,
  cream,
  ointment,
  gel,
  lotion,
  drops,
  inhaler,
  suppository,
  patch,
  powder,
  sachet,
  solution,
  spray,
  unknown;

  static DosageForm fromString(String? v) => DosageForm.values.firstWhere(
    (e) => e.name.toLowerCase() == v?.toLowerCase(),
    orElse: () => DosageForm.unknown,
  );

  String get displayName {
    switch (this) {
      case DosageForm.tablet:
        return 'Tablet';
      case DosageForm.capsule:
        return 'Capsule';
      case DosageForm.syrup:
        return 'Syrup';
      case DosageForm.suspension:
        return 'Suspension';
      case DosageForm.injection:
        return 'Injection';
      case DosageForm.cream:
        return 'Cream';
      case DosageForm.ointment:
        return 'Ointment';
      case DosageForm.gel:
        return 'Gel';
      case DosageForm.lotion:
        return 'Lotion';
      case DosageForm.drops:
        return 'Drops';
      case DosageForm.inhaler:
        return 'Inhaler';
      case DosageForm.suppository:
        return 'Suppository';
      case DosageForm.patch:
        return 'Patch';
      case DosageForm.powder:
        return 'Powder';
      case DosageForm.sachet:
        return 'Sachet';
      case DosageForm.solution:
        return 'Solution';
      case DosageForm.spray:
        return 'Spray';
      case DosageForm.unknown:
        return '';
    }
  }
}

enum ProductLifecycleStatus {
  draft,
  active,
  inactive,
  discontinued;

  static ProductLifecycleStatus fromString(String? v) =>
      ProductLifecycleStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ProductLifecycleStatus.draft,
      );

  bool get isPublished => this == ProductLifecycleStatus.active;
}

// -- Model --------------------------------------------------------------------

class Product extends Equatable {
  const Product({
    required this.id,
    required this.drugName,
    required this.genericName,
    required this.strength,
    required this.dosageForm,
    required this.manufacturer,
    required this.categoryId,
    required this.mrp,
    required this.salePrice,
    required this.discountPercent,
    this.isFlashSale = false,
    this.flashSalePrice,
    this.flashSaleStartAt,
    this.flashSaleEndAt,
    this.isFeatured = false,
    this.requiresPrescription = false,
    this.isAvailable = true,
    this.lifecycleStatus = ProductLifecycleStatus.draft,
    this.countInStock = 0,
    this.description = '',
    this.imageUrl = '',
    this.hasImage = false,
    this.searchTokens = const [],
    this.collections = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.createdBy = '',
  });

  final String id;
  final String drugName;
  final String genericName;
  final String strength;
  final DosageForm dosageForm;
  final String manufacturer;
  final String categoryId;
  final double mrp;
  final double salePrice;
  final int discountPercent;
  final bool isFlashSale;
  final double? flashSalePrice;
  final DateTime? flashSaleStartAt;
  final DateTime? flashSaleEndAt;
  final bool isFeatured;
  final bool requiresPrescription;
  final bool isAvailable;
  final ProductLifecycleStatus lifecycleStatus;
  final int countInStock;
  final String description;
  final String imageUrl;
  final bool hasImage;
  final List<String> searchTokens;
  final List<String> collections;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  bool get isCurrentlyFlashSale {
    if (!isFlashSale || flashSalePrice == null || flashSalePrice! <= 0) {
      return false;
    }
    final now = DateTime.now();
    if (flashSaleStartAt != null && now.isBefore(flashSaleStartAt!)) {
      return false;
    }
    if (flashSaleEndAt != null && now.isAfter(flashSaleEndAt!)) {
      return false;
    }
    return true;
  }

  double get effectivePrice =>
      isCurrentlyFlashSale ? flashSalePrice! : salePrice;

  bool get hasDiscount => discountPercent > 0;
  bool get isInStock => countInStock > 0;
  bool get isLowStock => countInStock > 0 && countInStock <= 5;

  factory Product.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? map['id'] as String? ?? '';

    final mrp = (map['mrp'] as num? ?? map['price'] as num? ?? 0).toDouble();
    final salePrice = (map['salePrice'] as num? ?? map['price'] as num? ?? mrp)
        .toDouble();
    final isFlashSaleFlag = map['isFlashSale'] as bool? ?? false;
    final flashPrice = (map['flashSalePrice'] as num?)?.toDouble();
    final startAtDate = _parseTimestamp(map['flashSaleStartAt']);
    final endAtDate = _parseTimestamp(map['flashSaleEndAt']);

    bool isCurrentlyFlashSale =
        isFlashSaleFlag && flashPrice != null && flashPrice > 0;
    final now = DateTime.now();
    if (isCurrentlyFlashSale &&
        startAtDate != null &&
        now.isBefore(startAtDate)) {
      isCurrentlyFlashSale = false;
    }
    if (isCurrentlyFlashSale && endAtDate != null && now.isAfter(endAtDate)) {
      isCurrentlyFlashSale = false;
    }

    final effectiveSalePrice = isCurrentlyFlashSale ? flashPrice! : salePrice;

    final computedDiscount = mrp > 0
        ? ((mrp - effectiveSalePrice) / mrp * 100).floor()
        : (map['discountPercent'] as num? ??
                  map['saleDiscountPercent'] as num? ??
                  0)
              .toInt();

    final cSlug =
        map['categorySlug'] as String? ?? map['category'] as String? ?? '';
    final cId = map['categoryId'] as String? ?? cSlug;

    return Product(
      id: id,
      drugName: map['drugName'] as String? ?? map['name'] as String? ?? '',
      genericName: map['genericName'] as String? ?? '',
      strength: map['strength'] as String? ?? '',
      dosageForm: DosageForm.fromString(map['dosageForm'] as String?),
      manufacturer:
          map['manufacturer'] as String? ?? map['brandName'] as String? ?? '',
      categoryId: cId,
      mrp: mrp,
      salePrice: salePrice,
      discountPercent: computedDiscount,
      isFlashSale: map['isFlashSale'] as bool? ?? false,
      flashSalePrice: (map['flashSalePrice'] as num?)?.toDouble(),
      flashSaleStartAt: startAtDate,
      flashSaleEndAt: endAtDate,
      isFeatured: map['isFeatured'] as bool? ?? false,
      requiresPrescription:
          map['requiresPrescription'] as bool? ??
          map['isRxRequired'] as bool? ??
          false,
      isAvailable: true,
      lifecycleStatus: ProductLifecycleStatus.fromString(
        map['lifecycleStatus'] as String?,
      ),
      countInStock: (map['countInStock'] as num? ?? 0).toInt(),
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      hasImage: map['hasImage'] as bool? ?? false,
      searchTokens:
          (map['searchTokens'] as List<dynamic>?)?.cast<String>() ??
          Product.generateSearchKeywords(
            map['drugName'] ?? map['name'] ?? '',
            map['genericName'] ?? '',
            map['manufacturer'] ?? map['brandName'] ?? '',
          ),
      collections:
          (map['collections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: (map['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] as num? ?? 0).toInt(),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  static DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<String> generateSearchKeywords(
    String drugName,
    String genericName,
    String brandName,
  ) {
    return ProductTokenizer.tokenize(drugName, genericName, brandName);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'drugName': drugName,
    'genericName': genericName,
    'strength': strength,
    'dosageForm': dosageForm.name,
    'manufacturer': manufacturer,
    'categoryId': categoryId,
    'mrp': mrp,
    'salePrice': salePrice,
    'discountPercent': discountPercent,
    'isFlashSale': isFlashSale,
    'flashSalePrice': flashSalePrice,
    'isFeatured': isFeatured,
    'requiresPrescription': requiresPrescription,
    'isAvailable': isAvailable,
    'lifecycleStatus': lifecycleStatus.name,
    'countInStock': countInStock,
    'description': description,
    'imageUrl': imageUrl,
    'hasImage': hasImage,
    'searchTokens': searchTokens,
    'collections': collections,
    'rating': rating,
    'reviewCount': reviewCount,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'createdBy': createdBy,
  };

  Product copyWith({
    String? id,
    String? drugName,
    String? genericName,
    String? strength,
    DosageForm? dosageForm,
    String? manufacturer,
    String? categoryId,
    double? mrp,
    double? salePrice,
    int? discountPercent,
    bool? isFlashSale,
    double? flashSalePrice,
    DateTime? flashSaleStartAt,
    DateTime? flashSaleEndAt,
    bool? isFeatured,
    bool? requiresPrescription,
    bool? isAvailable,
    ProductLifecycleStatus? lifecycleStatus,
    int? countInStock,
    String? description,
    String? imageUrl,
    bool? hasImage,
    List<String>? searchTokens,
    List<String>? collections,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) => Product(
    id: id ?? this.id,
    drugName: drugName ?? this.drugName,
    genericName: genericName ?? this.genericName,
    strength: strength ?? this.strength,
    dosageForm: dosageForm ?? this.dosageForm,
    manufacturer: manufacturer ?? this.manufacturer,
    categoryId: categoryId ?? this.categoryId,
    mrp: mrp ?? this.mrp,
    salePrice: salePrice ?? this.salePrice,
    discountPercent: discountPercent ?? this.discountPercent,
    isFlashSale: isFlashSale ?? this.isFlashSale,
    flashSalePrice: flashSalePrice ?? this.flashSalePrice,
    isFeatured: isFeatured ?? this.isFeatured,
    requiresPrescription: requiresPrescription ?? this.requiresPrescription,
    isAvailable: isAvailable ?? this.isAvailable,
    lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
    countInStock: countInStock ?? this.countInStock,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    hasImage: hasImage ?? this.hasImage,
    searchTokens: searchTokens ?? this.searchTokens,
    collections: collections ?? this.collections,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
  );

  @override
  List<Object?> get props => [
    id,
    drugName,
    genericName,
    strength,
    dosageForm,
    manufacturer,
    categoryId,
    mrp,
    salePrice,
    discountPercent,
    isFlashSale,
    flashSalePrice,
    isFeatured,
    requiresPrescription,
    isAvailable,
    lifecycleStatus,
    countInStock,
    description,
    imageUrl,
    hasImage,
    searchTokens,
    rating,
    reviewCount,
    createdAt,
    updatedAt,
    createdBy,
  ];
}
