import '../repository/sessions_repository.dart';

class RevokeSessionUseCase {
  const RevokeSessionUseCase(this._repository);

  final SessionsRepository _repository;

  Future<void> call(String id) => _repository.revokeSession(id);
}