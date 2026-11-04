class Product {
  const Product({
    required this.id,
    required this.name,
    required this.weightInGrams,
    required this.price,
    required this.imageUrl,
    required this.isActive,
    this.categoryId,
    this.categoryName,
    this.unit = 'шт',
    this.stockQuantity = 0,
  });

  static const lowStockThreshold = 10;

  final String id;
  final String name;
  final int? weightInGrams;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  final int stockQuantity;

  bool get inStock => stockQuantity > 0;

  bool get isLowStock => inStock && stockQuantity <= lowStockThreshold;
}