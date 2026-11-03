import '../entities/device_session.dart';

abstract class SessionsRepository {
  Future<List<DeviceSession>> getSessions();

  Future<void> revokeSession(String id);
}