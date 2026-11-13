import '../repository/product_management_repository.dart';

class WriteOffStockUseCase {
  WriteOffStockUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(String productId, int quantity, String comment) =>
      _repository.writeOffStock(productId, quantity, comment);
}