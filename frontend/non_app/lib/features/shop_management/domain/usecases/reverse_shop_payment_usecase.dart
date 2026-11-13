import '../repository/shop_management_repository.dart';

class ReverseShopPaymentUseCase {
  ReverseShopPaymentUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<void> call(String id, String reason) =>
      _repository.reversePayment(id, reason);
}