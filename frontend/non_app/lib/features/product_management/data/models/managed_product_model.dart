import '../../domain/entities/managed_product.dart';

class ManagedProductModel extends ManagedProduct {
  const ManagedProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.unit,
    required super.stockQuantity,
    required super.isActive,
    super.weightInGrams,
    super.imageUrl,
    super.categoryId,
    super.categoryName,
  });

  factory ManagedProductModel.fromJson(Map<String, dynamic> json) {
    return ManagedProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'шт',
      stockQuantity: (json['stockQuantity'] as num? ?? 0).toInt(),
      isActive: json['isActive'] as bool? ?? true,
      weightInGrams: (json['weightInGrams'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
    );
  }
}