import '../../../../core/models/paged_result.dart';
import '../../../../core/network/api_client.dart';
import '../models/shop_balance_model.dart';
import '../models/shop_model.dart';

class ShopsRemoteDataSource {
  ShopsRemoteDataSource(this._client);

  final ApiClient _client;

    Map<String, dynamic> _body({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    double? latitude,
    double? longitude,
  }) {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      if (contactName != null) 'contactName': contactName,
      if (latitude != null && longitude != null) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }

  Future<ShopModel> getMyShop() async {
    final data = await _client.get('/api/Shops/my');

    return ShopModel.fromJson(data as Map<String, dynamic>);
  }

    Future<ShopModel> createMyShop({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client.post(
      '/api/Shops/my',
      data: _body(
        name: name,
        address: address,
        phone: phone,
        contactName: contactName,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    return ShopModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ShopBalanceModel> getMyBalance() async {
    final data = await _client.get('/api/Shops/my/balance');

    return ShopBalanceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PagedResult<ShopModel>> getShops({
    String? search,
    required int page,
    required int pageSize,
  }) async {
    final path = Uri(
      path: '/api/Shops',
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IsActive': 'true',
        if (search != null && search.isNotEmpty) 'Search': search,
      },
    ).toString();

    final data = await _client.get(path);

    return PagedResult.fromJson(data, ShopModel.fromJson, page: page, pageSize: pageSize);
  }

    Future<ShopModel> createShop({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client.post(
      '/api/Shops',
      data: _body(
        name: name,
        address: address,
        phone: phone,
        contactName: contactName,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    return ShopModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ShopModel> setShopLocation(String id, {double? latitude, double? longitude}) async {
    final data = await _client.put(
      '/api/Shops/$id/location',
      data: {'latitude': latitude, 'longitude': longitude},
    );

    return ShopModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ShopBalanceModel> getShopBalance(String id) async {
    final data = await _client.get('/api/Shops/$id/balance');

    return ShopBalanceModel.fromJson(data as Map<String, dynamic>);
  }
}