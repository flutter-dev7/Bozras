class SalesDay {
  const SalesDay({
    required this.date,
    required this.ordersCount,
    required this.amount,
  });

  final DateTime date;
  final int ordersCount;
  final double amount;
}

class SalesProduct {
  const SalesProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.amount,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double amount;
}

class SalesReport {
  const SalesReport({
    required this.ordersCount,
    required this.totalQuantity,
    required this.totalAmount,
    required this.receivedPayments,
    required this.byDay,
    required this.byProduct,
  });

  final int ordersCount;
  final int totalQuantity;
  final double totalAmount;
  final double receivedPayments;
  final List<SalesDay> byDay;
  final List<SalesProduct> byProduct;
}