import '../repository/supplier_repository.dart';

class ApproveShopRequestUseCase {
  ApproveShopRequestUseCase(this._repository);

  final SupplierRepository _repository;

  Future<void> call(String id) => _repository.approveRequest(id);
}