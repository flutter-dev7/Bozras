import '../../../../core/network/api_client.dart';
import '../models/device_session_model.dart';

class SessionsRemoteDataSource {
  SessionsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<DeviceSessionModel>> getSessions(String? currentSessionId) async {
    final path = Uri(
      path: '/api/auth/sessions',
      queryParameters: {
        if (currentSessionId != null) 'currentSessionId': currentSessionId,
      },
    ).toString();

    final data = await _client.get(path);

    return (data as List)
        .map((e) => DeviceSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeSession(String id) async {
    await _client.delete('/api/auth/sessions/$id');
  }
}