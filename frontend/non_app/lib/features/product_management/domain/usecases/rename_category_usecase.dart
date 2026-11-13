import '../repository/product_management_repository.dart';

class RenameCategoryUseCase {
  RenameCategoryUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(String id, String name) =>
      _repository.renameCategory(id, name);
}