import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/payment_method.dart';
import '../../domain/entities/shop_payment.dart';

class ShopPaymentModel extends ShopPayment {
  const ShopPaymentModel({
    required super.id,
    required super.amount,
    required super.method,
    required super.isReversal,
    required super.isReversed,
    required super.createdAt,
    super.orderId,
    super.receivedByName,
    super.reversalReason,
  });

  factory ShopPaymentModel.fromJson(Map<String, dynamic> json) {
    final method = json['method'] as String?;

    return ShopPaymentModel(
      id: json['id'] as String,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (m) => m.apiName == method,
        orElse: () => PaymentMethod.values.first,
      ),
      isReversal: json['isReversal'] as bool? ?? false,
      isReversed: json['isReversed'] as bool? ?? false,
      createdAt: Formatters.parseDateTime(json['createdAt'] as String),
      orderId: json['orderId'] as String?,
      receivedByName: json['receivedByName'] as String?,
      reversalReason: json['reversalReason'] as String?,
    );
  }
}