import '../repository/shop_management_repository.dart';

class SetShopOwnerUseCase {
  SetShopOwnerUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<void> call(String id, String ownerPhone) =>
      _repository.setOwner(id, ownerPhone);
}