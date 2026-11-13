import '../../../../core/models/paged_result.dart';
import '../entities/managed_product.dart';
import '../entities/product_category.dart';
import '../entities/product_input.dart';

abstract class ProductManagementRepository {
  Future<PagedResult<ManagedProduct>> getProducts({
    String? search,
    bool? isActive,
    String? categoryId,
    required int page,
    required int pageSize,
  });

  Future<void> createProduct(ProductInput input);

  Future<void> updateProduct(String id, ProductInput input, bool isActive);

  Future<List<ProductCategory>> getCategories();

  Future<void> createCategory(String name);

  Future<void> renameCategory(String id, String name);

  Future<void> deleteCategory(String id);

  Future<void> receiveStock(String productId, int quantity, String? comment);

  Future<void> writeOffStock(String productId, int quantity, String comment);
}