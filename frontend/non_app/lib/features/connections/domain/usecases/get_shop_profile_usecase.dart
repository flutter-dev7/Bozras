import '../entities/shop_profile.dart';
import '../repository/connections_repository.dart';

class GetShopProfileUseCase {
  const GetShopProfileUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<ShopProfile?> call() => _repository.getProfile();
}