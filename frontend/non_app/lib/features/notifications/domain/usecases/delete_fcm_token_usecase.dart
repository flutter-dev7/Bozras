import '../repository/devices_repository.dart';

class DeleteFcmTokenUseCase {
  const DeleteFcmTokenUseCase(this._repository);

  final DevicesRepository _repository;

  Future<void> call(String token) => _repository.deleteFcmToken(token);
}