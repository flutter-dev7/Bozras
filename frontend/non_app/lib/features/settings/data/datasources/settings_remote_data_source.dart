import '../../../../core/network/api_client.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<String> getOrderCutoffTime() async {
    final data = await _client.get('/api/Settings');

    return (data as Map<String, dynamic>)['orderCutoffTime'] as String;
  }

  Future<void> updateOrderCutoffTime(String time) async {
    await _client.put('/api/Settings', data: {'orderCutoffTime': time});
  }
}