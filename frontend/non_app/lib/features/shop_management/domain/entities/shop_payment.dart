import '../../../orders/domain/entities/payment_method.dart';

class ShopPayment {
  const ShopPayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.isReversal,
    required this.isReversed,
    required this.createdAt,
    this.orderId,
    this.receivedByName,
    this.reversalReason,
  });

  final String id;
  final double amount;
  final PaymentMethod method;
  final bool isReversal;
  final bool isReversed;
  final DateTime createdAt;
  final String? orderId;
  final String? receivedByName;
  final String? reversalReason;

  bool get canReverse => !isReversal && !isReversed;
}