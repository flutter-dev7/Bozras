import '../repository/product_management_repository.dart';

class DeleteCategoryUseCase {
  DeleteCategoryUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(String id) => _repository.deleteCategory(id);
}