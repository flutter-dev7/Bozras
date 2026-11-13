import '../../../../core/models/paged_result.dart';
import '../entities/managed_shop.dart';
import '../repository/shop_management_repository.dart';

class GetManagedShopsUseCase {
  GetManagedShopsUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<PagedResult<ManagedShop>> call({
    String? search,
    bool? isActive,
    required int page,
    required int pageSize,
  }) => _repository.getShops(
    search: search,
    isActive: isActive,
    page: page,
    pageSize: pageSize,
  );
}