import '../entities/product_input.dart';
import '../repository/product_management_repository.dart';

class CreateProductUseCase {
  CreateProductUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(ProductInput input) => _repository.createProduct(input);
}