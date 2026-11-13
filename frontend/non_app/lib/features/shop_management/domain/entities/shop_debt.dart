class ShopDebt {
  const ShopDebt({
    required this.shopId,
    required this.shopName,
    required this.shopPhone,
    required this.debt,
    required this.isOverLimit,
    this.debtLimit,
  });

  final String shopId;
  final String shopName;
  final String shopPhone;
  final double debt;
  final double? debtLimit;
  final bool isOverLimit;
}