import '../entities/supplier_card.dart';
import '../repository/connections_repository.dart';

class ConnectToSupplierUseCase {
  const ConnectToSupplierUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<SupplierCard> call(String supplierId) => _repository.connectTo(supplierId);
}