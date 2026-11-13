import '../repository/product_management_repository.dart';

class ReceiveStockUseCase {
  ReceiveStockUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<void> call(String productId, int quantity, String? comment) =>
      _repository.receiveStock(productId, quantity, comment);
}