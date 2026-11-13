import '../repository/shop_management_repository.dart';

class SetDebtLimitUseCase {
  SetDebtLimitUseCase(this._repository);

  final ShopManagementRepository _repository;

  Future<void> call(String id, double? limit) =>
      _repository.setDebtLimit(id, limit);
}