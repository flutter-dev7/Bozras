import '../entities/shop_request.dart';
import '../repository/supplier_repository.dart';

class GetShopRequestsUseCase {
  GetShopRequestsUseCase(this._repository);

  final SupplierRepository _repository;

  Future<List<ShopRequest>> call() => _repository.getRequests();
}