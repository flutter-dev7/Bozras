import '../entities/shop_balance.dart';
import '../repository/shop_management_repository.dart';

class GetShopBalanceUseCase {
  GetShopBalanceUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<ShopBalance> call(String id) => _repository.getBalance(id);
}