import '../../../../core/utils/formatters.dart';
import '../../domain/entities/shop_balance.dart';

class ShopBalanceModel extends ShopBalance {
  const ShopBalanceModel({
    required super.deliveredTotal,
    required super.paidTotal,
    required super.debt,
    required super.unpaidOrders,
    super.debtLimit,
  });

  factory ShopBalanceModel.fromJson(Map<String, dynamic> json) {
    return ShopBalanceModel(
      deliveredTotal: (json['deliveredTotal'] as num? ?? 0).toDouble(),
      paidTotal: (json['paidTotal'] as num? ?? 0).toDouble(),
      debt: (json['debt'] as num? ?? 0).toDouble(),
      debtLimit: (json['debtLimit'] as num?)?.toDouble(),
      unpaidOrders: (json['unpaidOrders'] as List? ?? const []).map((e) {
        final item = e as Map<String, dynamic>;

        return UnpaidOrder(
          orderId: item['orderId'] as String,
          deliveryDate: Formatters.parseDate(item['deliveryDate'] as String),
          totalAmount: (item['totalAmount'] as num? ?? 0).toDouble(),
          paidAmount: (item['paidAmount'] as num? ?? 0).toDouble(),
          remainingAmount: (item['remainingAmount'] as num? ?? 0).toDouble(),
        );
      }).toList(),
    );
  }
}