abstract class DevicesRepository {
  Future<void> saveFcmToken(String token);

  Future<void> deleteFcmToken(String token);
}