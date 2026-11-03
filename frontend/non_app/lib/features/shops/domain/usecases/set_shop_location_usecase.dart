import '../entities/shop.dart';
import '../repository/shops_repository.dart';

class SetShopLocationUseCase {
  const SetShopLocationUseCase(this._repository);

  final ShopsRepository _repository;

  Future<Shop> call(String id, {double? latitude, double? longitude}) {
    return _repository.setShopLocation(id, latitude: latitude, longitude: longitude);
  }
}