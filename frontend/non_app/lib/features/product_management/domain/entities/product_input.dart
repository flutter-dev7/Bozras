class ProductInput {
  const ProductInput({
    required this.name,
    required this.price,
    required this.unit,
    this.weightInGrams,
    this.imageUrl,
    this.categoryId,
  });

  final String name;
  final double price;
  final String unit;
  final int? weightInGrams;
  final String? imageUrl;
  final String? categoryId;
}