import '../repository/devices_repository.dart';

class SaveFcmTokenUseCase {
  const SaveFcmTokenUseCase(this._repository);

  final DevicesRepository _repository;

  Future<void> call(String token) => _repository.saveFcmToken(token);
}