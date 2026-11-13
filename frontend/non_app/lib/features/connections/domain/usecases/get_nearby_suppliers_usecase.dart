import '../entities/supplier_card.dart';
import '../repository/connections_repository.dart';

class GetNearbySuppliersUseCase {
  const GetNearbySuppliersUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<List<SupplierCard>> call(String search) => _repository.getNearby(search);
}