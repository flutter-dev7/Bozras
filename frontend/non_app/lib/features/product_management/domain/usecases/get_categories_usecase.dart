import '../entities/product_category.dart';
import '../repository/product_management_repository.dart';

class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<List<ProductCategory>> call() => _repository.getCategories();
}