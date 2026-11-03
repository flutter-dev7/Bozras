import '../entities/device_session.dart';
import '../repository/sessions_repository.dart';

class GetSessionsUseCase {
  const GetSessionsUseCase(this._repository);

  final SessionsRepository _repository;

  Future<List<DeviceSession>> call() => _repository.getSessions();
}