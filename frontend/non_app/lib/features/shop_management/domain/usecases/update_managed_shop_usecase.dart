import '../repository/shop_management_repository.dart';

class UpdateManagedShopUseCase {
  UpdateManagedShopUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<void> call(
    String id, {
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required bool isActive,
  }) => _repository.updateShop(
    id,
    name: name,
    address: address,
    phone: phone,
    contactName: contactName,
    isActive: isActive,
  );
}