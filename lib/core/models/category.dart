import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/category_icon_registry.dart';

class AppCategory extends Equatable {
  const AppCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
    required this.colorHex,
    this.nameBn = '',
    this.parentId,
    this.depth = 0,
    this.imageUrl = '',
    this.description = '',
    this.sortOrder = 100,
    this.isActive = true,
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String nameBn;
  final String slug;
  final String? parentId;
  final int depth;
  final String iconKey;
  final String colorHex;
  final String imageUrl;
  final String description;
  final int sortOrder;
  final bool isActive;
  final int productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRoot => parentId == null;
  bool get isSub => parentId != null;

  Color get color => CategoryIconRegistry.getColor(slug);

  IconData get icon => CategoryIconRegistry.getIcon(slug);

  factory AppCategory.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppCategory(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameBn: map['nameBn'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      parentId: map['parentId'] as String?,
      depth: (map['depth'] as num? ?? 0).toInt(),
      iconKey: map['iconKey'] as String? ?? 'category',
      colorHex: map['colorHex'] as String? ?? '#607D8B',
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      sortOrder: (map['sortOrder'] as num? ?? 100).toInt(),
      isActive: map['isActive'] as bool? ?? true,
      productCount: (map['productCount'] as num? ?? 0).toInt(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameBn': nameBn,
      'slug': slug,
      'parentId': parentId,
      'depth': depth,
      'iconKey': iconKey,
      'colorHex': colorHex,
      'imageUrl': imageUrl,
      'description': description,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'productCount': productCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AppCategory copyWith({
    String? id,
    String? name,
    String? nameBn,
    String? slug,
    String? parentId,
    int? depth,
    String? iconKey,
    String? colorHex,
    String? imageUrl,
    String? description,
    int? sortOrder,
    bool? isActive,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      slug: slug ?? this.slug,
      parentId: parentId ?? this.parentId,
      depth: depth ?? this.depth,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    parentId,
    iconKey,
    colorHex,
    isActive,
    sortOrder,
  ];
}
