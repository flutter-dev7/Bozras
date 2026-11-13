import '../entities/courier.dart';
import '../repository/orders_repository.dart';

class GetCouriersUseCase {
  GetCouriersUseCase(this._repository);

  final OrdersRepository _repository;

  Future<List<Courier>> call() => _repository.getCouriers();
}