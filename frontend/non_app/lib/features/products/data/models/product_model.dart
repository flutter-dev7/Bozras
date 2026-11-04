import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.weightInGrams,
    required super.price,
    required super.imageUrl,
    required super.isActive,
    super.categoryId,
    super.categoryName,
    super.unit,
    super.stockQuantity,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      weightInGrams: (json['weightInGrams'] as num?)?.toInt(),
      price: (json['price'] as num? ?? 0).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      unit: json['unit'] as String? ?? 'шт',
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    );
  }
}