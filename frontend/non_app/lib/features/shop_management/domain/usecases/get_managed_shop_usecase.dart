import '../entities/managed_shop.dart';
import '../repository/shop_management_repository.dart';

class GetManagedShopUseCase {
  GetManagedShopUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<ManagedShop> call(String id) => _repository.getShop(id);
}