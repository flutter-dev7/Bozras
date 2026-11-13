import '../entities/product_input.dart';
import '../repository/product_management_repository.dart';

class UpdateProductUseCase {
  UpdateProductUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(String id, ProductInput input, bool isActive) =>
      _repository.updateProduct(id, input, isActive);
}