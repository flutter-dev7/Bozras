import '../../../../core/models/paged_result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/product_input.dart';
import '../models/managed_product_model.dart';
import '../models/product_category_model.dart';

class ProductManagementRemoteDataSource {
  ProductManagementRemoteDataSource(this._client);

  final ApiClient _client;

  Future<PagedResult<ManagedProductModel>> getProducts({
    String? search,
    bool? isActive,
    String? categoryId,
    required int page,
    required int pageSize,
  }) async {
    final path = Uri(
      path: '/api/Products/manage',
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'Search': search,
        if (isActive != null) 'IsActive': '$isActive',
        if (categoryId != null) 'CategoryId': categoryId,
      },
    ).toString();

    final data = await _client.get(path);

    return PagedResult.fromJson(
      data,
      ManagedProductModel.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> _body(ProductInput input) => {
    'name': input.name,
    'weightInGrams': input.weightInGrams,
    'price': input.price,
    'imageUrl': input.imageUrl,
    'categoryId': input.categoryId,
    'unit': input.unit,
  };

  Future<void> createProduct(ProductInput input) async {
    await _client.post('/api/Products', data: _body(input));
  }

  Future<void> updateProduct(
    String id,
    ProductInput input,
    bool isActive,
  ) async {
    await _client.put(
      '/api/Products/$id',
      data: {..._body(input), 'isActive': isActive},
    );
  }

  Future<List<ProductCategoryModel>> getCategories() async {
    final data = await _client.get('/api/Categories');

    return (data as List)
        .map((e) => ProductCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory(String name) async {
    await _client.post('/api/Categories', data: {'name': name});
  }

  Future<void> renameCategory(String id, String name) async {
    await _client.put('/api/Categories/$id', data: {'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/api/Categories/$id');
  }

  Future<void> receiveStock(
    String productId,
    int quantity,
    String? comment,
  ) async {
    await _client.post(
      '/api/Stock/receipts',
      data: {'productId': productId, 'quantity': quantity, 'comment': comment},
    );
  }

  Future<void> writeOffStock(
    String productId,
    int quantity,
    String comment,
  ) async {
    await _client.post(
      '/api/Stock/write-offs',
      data: {'productId': productId, 'quantity': quantity, 'comment': comment},
    );
  }
}