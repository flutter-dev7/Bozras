import '../repository/supplier_repository.dart';

class RejectShopRequestUseCase {
  RejectShopRequestUseCase(this._repository);

  final SupplierRepository _repository;

  Future<void> call(String id) => _repository.rejectRequest(id);
}