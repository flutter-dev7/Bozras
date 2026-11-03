import '../../../../core/storage/session_id_storage.dart';
import '../../domain/entities/device_session.dart';
import '../../domain/repository/sessions_repository.dart';
import '../datasources/sessions_remote_data_source.dart';

class SessionsRepositoryImpl implements SessionsRepository {
  SessionsRepositoryImpl(this._remote);

  final SessionsRemoteDataSource _remote;

  @override
  Future<List<DeviceSession>> getSessions() async {
    return _remote.getSessions(await SessionIdStorage.read());
  }

  @override
  Future<void> revokeSession(String id) => _remote.revokeSession(id);
}