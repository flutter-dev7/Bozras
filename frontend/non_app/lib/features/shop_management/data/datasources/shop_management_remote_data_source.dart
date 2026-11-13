import 'package:non_app/features/shop_management/data/models/shop_debt_model.dart';

import '../../../../core/models/paged_result.dart';
import '../../../../core/network/api_client.dart';
import '../../../orders/domain/entities/payment_method.dart';
import '../models/managed_shop_model.dart';
import '../models/shop_balance_model.dart';
import '../models/shop_payment_model.dart';

class ShopManagementRemoteDataSource {
  ShopManagementRemoteDataSource(this._client);

  final ApiClient _client;

  Future<PagedResult<ManagedShopModel>> getShops({
    String? search,
    bool? isActive,
    required int page,
    required int pageSize,
  }) async {
    final path = Uri(
      path: '/api/Shops',
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'Search': search,
        if (isActive != null) 'IsActive': '$isActive',
      },
    ).toString();

    final data = await _client.get(path);

    return PagedResult.fromJson(
      data,
      ManagedShopModel.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ManagedShopModel> getShop(String id) async {
    final data = await _client.get('/api/Shops/$id');

    return ManagedShopModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ShopBalanceModel> getBalance(String id) async {
    final data = await _client.get('/api/Shops/$id/balance');

    return ShopBalanceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateShop(
    String id, {
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required bool isActive,
  }) async {
    await _client.put(
      '/api/Shops/$id',
      data: {
        'name': name,
        'address': address,
        'phone': phone,
        if (contactName != null) 'contactName': contactName,
        'isActive': isActive,
      },
    );
  }

  Future<void> setDebtLimit(String id, double? limit) async {
    await _client.put('/api/Shops/$id/debt-limit', data: {'debtLimit': limit});
  }

  Future<void> setOwner(String id, String ownerPhone) async {
    await _client.put('/api/Shops/$id/owner', data: {'ownerPhone': ownerPhone});
  }

  Future<List<ShopPaymentModel>> getPayments(String shopId) async {
    final path = Uri(
      path: '/api/Payments',
      queryParameters: {'ShopId': shopId, 'Page': '1', 'PageSize': '50'},
    ).toString();

    final data = await _client.get(path);

    return PagedResult.fromJson(
      data,
      ShopPaymentModel.fromJson,
      page: 1,
      pageSize: 50,
    ).items;
  }

  Future<void> createPayment({
    required String shopId,
    String? orderId,
    required double amount,
    required PaymentMethod method,
  }) async {
    await _client.post(
      '/api/Payments',
      data: {
        'shopId': shopId,
        if (orderId != null) 'orderId': orderId,
        'amount': amount,
        'method': method.apiName,
      },
    );
  }

  Future<void> reversePayment(String id, String reason) async {
    await _client.post('/api/Payments/$id/reverse', data: {'reason': reason});
  }

  Future<List<ShopDebtModel>> getDebts() async {
    final path = Uri(
      path: '/api/Debts',
      queryParameters: {'Page': '1', 'PageSize': '100'},
    ).toString();

    final data = await _client.get(path);

    return PagedResult.fromJson(
      data,
      ShopDebtModel.fromJson,
      page: 1,
      pageSize: 100,
    ).items;
  }
}
