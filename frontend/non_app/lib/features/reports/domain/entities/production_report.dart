class ProductionItem {
  const ProductionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final int quantity;
}

class ProductionReport {
  const ProductionReport({
    required this.ordersCount,
    required this.totalQuantity,
    required this.items,
  });

  final int ordersCount;
  final int totalQuantity;
  final List<ProductionItem> items;
}