import '../../../../core/network/api_client.dart';
import '../models/shop_request_model.dart';
import '../models/supplier_profile_model.dart';

class SupplierRemoteDataSource {
  SupplierRemoteDataSource(this._client);

  final ApiClient _client;

  Future<SupplierProfileModel> getProfile() async {
    final data = await _client.get('/api/supplier');

    return SupplierProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateProfile({
    String? phone,
    String? description,
    required bool requiresApproval,
  }) async {
    await _client.put(
      '/api/supplier',
      data: {
        'phone': phone,
        'description': description,
        'requiresApproval': requiresApproval,
      },
    );
  }

  Future<SupplierProfileModel> regenerateCode() async {
    final data = await _client.post('/api/supplier/regenerate-code');

    return SupplierProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ShopRequestModel>> getRequests() async {
    final data = await _client.get('/api/Shops/requests');

    return (data as List)
        .map((e) => ShopRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveRequest(String id) async {
    await _client.post('/api/Shops/$id/approve');
  }

  Future<void> rejectRequest(String id) async {
    await _client.post('/api/Shops/$id/reject');
  }
}