import '../entities/shop_debt.dart';
import '../repository/shop_management_repository.dart';

class GetShopDebtsUseCase {
  GetShopDebtsUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<List<ShopDebt>> call() => _repository.getDebts();
}