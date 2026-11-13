import '../../../../core/models/paged_result.dart';
import '../../domain/entities/managed_product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_input.dart';
import '../../domain/repository/product_management_repository.dart';
import '../datasources/product_management_remote_data_source.dart';

class ProductManagementRepositoryImpl implements ProductManagementRepository {
  ProductManagementRepositoryImpl(this._remote);

  final ProductManagementRemoteDataSource _remote;

  @override
  Future<PagedResult<ManagedProduct>> getProducts({
    String? search,
    bool? isActive,
    String? categoryId,
    required int page,
    required int pageSize,
  }) async {
    final result = await _remote.getProducts(
      search: search,
      isActive: isActive,
      categoryId: categoryId,
      page: page,
      pageSize: pageSize,
    );

    return PagedResult<ManagedProduct>(
      items: result.items,
      hasMore: result.hasMore,
    );
  }

  @override
  Future<void> createProduct(ProductInput input) => _remote.createProduct(input);

  @override
  Future<void> updateProduct(String id, ProductInput input, bool isActive) =>
      _remote.updateProduct(id, input, isActive);

  @override
  Future<List<ProductCategory>> getCategories() => _remote.getCategories();

  @override
  Future<void> createCategory(String name) => _remote.createCategory(name);

  @override
  Future<void> renameCategory(String id, String name) =>
      _remote.renameCategory(id, name);

  @override
  Future<void> deleteCategory(String id) => _remote.deleteCategory(id);

  @override
  Future<void> receiveStock(String productId, int quantity, String? comment) =>
      _remote.receiveStock(productId, quantity, comment);

  @override
  Future<void> writeOffStock(String productId, int quantity, String comment) =>
      _remote.writeOffStock(productId, quantity, comment);
}