import '../../../orders/domain/entities/payment_method.dart';
import '../repository/shop_management_repository.dart';

class CreateShopPaymentUseCase {
  CreateShopPaymentUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<void> call({
    required String shopId,
    String? orderId,
    required double amount,
    required PaymentMethod method,
  }) => _repository.createPayment(
    shopId: shopId,
    orderId: orderId,
    amount: amount,
    method: method,
  );
}