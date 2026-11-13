import '../entities/supplier_card.dart';
import '../repository/connections_repository.dart';

class ConnectByCodeUseCase {
  const ConnectByCodeUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<SupplierCard> call(String code) => _repository.connectByCode(code);
}