import '../entities/shop_profile.dart';
import '../repository/connections_repository.dart';

class SaveShopProfileUseCase {
  const SaveShopProfileUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<ShopProfile> call({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required String locationId,
    double? latitude,
    double? longitude,
  }) {
    return _repository.saveProfile(
      name: name,
      address: address,
      phone: phone,
      contactName: contactName,
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}