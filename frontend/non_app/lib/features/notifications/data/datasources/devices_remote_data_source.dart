import '../../../../core/network/api_client.dart';

class DevicesRemoteDataSource {
  DevicesRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> saveFcmToken(String token) async {
    await _client.put('/api/Devices/fcm-token', data: {'token': token});
  }

  Future<void> deleteFcmToken(String token) async {
    await _client.delete('/api/Devices/fcm-token', data: {'token': token});
  }
}