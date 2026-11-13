import '../repository/orders_repository.dart';

class AssignCourierUseCase {
  AssignCourierUseCase(this._repository);

  final OrdersRepository _repository;

  Future<void> call(String orderId, String courierId) =>
      _repository.assignCourier(orderId, courierId);
}