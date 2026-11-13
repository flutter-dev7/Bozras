import '../entities/my_supplier.dart';
import '../repository/connections_repository.dart';

class GetMySuppliersUseCase {
  const GetMySuppliersUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<List<MySupplier>> call() => _repository.getMySuppliers();
}