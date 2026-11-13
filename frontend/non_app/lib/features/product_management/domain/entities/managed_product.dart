class ManagedProduct {
  const ManagedProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    required this.isActive,
    this.weightInGrams,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  final String id;
  final String name;
  final double price;
  final String unit;
  final int stockQuantity;
  final bool isActive;
  final int? weightInGrams;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;
}