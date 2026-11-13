import '../../../../core/network/api_client.dart';
import '../models/location_item_model.dart';
import '../models/my_supplier_model.dart';
import '../models/shop_profile_model.dart';
import '../models/supplier_card_model.dart';

class ConnectionsRemoteDataSource {
  ConnectionsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ShopProfileModel> getProfile() async {
    final data = await _client.get('/api/connections/profile');

    return ShopProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ShopProfileModel> saveProfile({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required String locationId,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client.put(
      '/api/connections/profile',
      data: {
        'name': name,
        'address': address,
        'phone': phone,
        if (contactName != null) 'contactName': contactName,
        'locationId': locationId,
        if (latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
      },
    );

    return ShopProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SupplierCardModel>> getNearby(String search) async {
    final data = await _client.get(
      '/api/connections/suppliers/nearby',
      query: {if (search.isNotEmpty) 'search': search},
    );

    return (data as List)
        .map((e) => SupplierCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MySupplierModel>> getMySuppliers() async {
    final data = await _client.get('/api/connections/suppliers');

    return (data as List)
        .map((e) => MySupplierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupplierCardModel> connectByCode(String code) async {
    final data = await _client.post(
      '/api/connections/suppliers/connect',
      data: {'code': code},
    );

    return SupplierCardModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SupplierCardModel> connectTo(String supplierId) async {
    final data = await _client.post('/api/connections/suppliers/$supplierId/connect');

    return SupplierCardModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<LocationItemModel>> getLocations() async {
    final data = await _client.get('/api/locations');

    return (data as List)
        .map((e) => LocationItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}