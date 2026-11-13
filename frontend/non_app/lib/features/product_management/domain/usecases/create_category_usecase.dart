import '../repository/product_management_repository.dart';

class CreateCategoryUseCase {
  CreateCategoryUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(String name) => _repository.createCategory(name);
}