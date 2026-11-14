import '../repository/settings_repository.dart';

class UpdateOrderCutoffUseCase {
  const UpdateOrderCutoffUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(String time) => _repository.updateOrderCutoffTime(time);
}