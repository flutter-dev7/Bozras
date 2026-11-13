import '../entities/shop_payment.dart';
import '../repository/shop_management_repository.dart';

class GetShopPaymentsUseCase {
  GetShopPaymentsUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<List<ShopPayment>> call(String shopId) =>
      _repository.getPayments(shopId);
}