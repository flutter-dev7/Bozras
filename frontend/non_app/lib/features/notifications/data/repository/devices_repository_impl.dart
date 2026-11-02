import '../../domain/repository/devices_repository.dart';
import '../datasources/devices_remote_data_source.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  DevicesRepositoryImpl(this._remote);

  final DevicesRemoteDataSource _remote;

  @override
  Future<void> saveFcmToken(String token) => _remote.saveFcmToken(token);

  @override
  Future<void> deleteFcmToken(String token) => _remote.deleteFcmToken(token);
}