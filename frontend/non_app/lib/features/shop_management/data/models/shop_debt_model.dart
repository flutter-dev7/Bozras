import '../../domain/entities/shop_debt.dart';

class ShopDebtModel extends ShopDebt {
  const ShopDebtModel({
    required super.shopId,
    required super.shopName,
    required super.shopPhone,
    required super.debt,
    required super.isOverLimit,
    super.debtLimit,
  });

  factory ShopDebtModel.fromJson(Map<String, dynamic> json) {
    return ShopDebtModel(
      shopId: json['shopId'] as String,
      shopName: json['shopName'] as String? ?? '',
      shopPhone: json['shopPhone'] as String? ?? '',
      debt: (json['debt'] as num? ?? 0).toDouble(),
      debtLimit: (json['debtLimit'] as num?)?.toDouble(),
      isOverLimit: json['isOverLimit'] as bool? ?? false,
    );
  }
}