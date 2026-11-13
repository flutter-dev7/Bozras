import '../../../../core/models/paged_result.dart';
import '../entities/managed_product.dart';
import '../repository/product_management_repository.dart';

class GetManagedProductsUseCase {
  GetManagedProductsUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<PagedResult<ManagedProduct>> call({
    String? search,
    bool? isActive,
    String? categoryId,
    required int page,
    required int pageSize,
  }) => _repository.getProducts(
    search: search,
    isActive: isActive,
    categoryId: categoryId,
    page: page,
    pageSize: pageSize,
  );
}