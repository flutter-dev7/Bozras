import 'package:non_app/features/shop_management/domain/entities/shop_debt.dart';

import '../../../../core/models/paged_result.dart';
import '../../../orders/domain/entities/payment_method.dart';
import '../../domain/entities/managed_shop.dart';
import '../../domain/entities/shop_balance.dart';
import '../../domain/entities/shop_payment.dart';
import '../../domain/repository/shop_management_repository.dart';
import '../datasources/shop_management_remote_data_source.dart';

class ShopManagementRepositoryImpl implements ShopManagementRepository {
  ShopManagementRepositoryImpl(this._remote);

  final ShopManagementRemoteDataSource _remote;

  @override
  Future<PagedResult<ManagedShop>> getShops({
    String? search,
    bool? isActive,
    required int page,
    required int pageSize,
  }) async {
    final result = await _remote.getShops(
      search: search,
      isActive: isActive,
      page: page,
      pageSize: pageSize,
    );

    return PagedResult<ManagedShop>(
      items: result.items,
      hasMore: result.hasMore,
    );
  }

  @override
  Future<ManagedShop> getShop(String id) => _remote.getShop(id);

  @override
  Future<ShopBalance> getBalance(String id) => _remote.getBalance(id);

  @override
  Future<void> updateShop(
    String id, {
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required bool isActive,
  }) => _remote.updateShop(
    id,
    name: name,
    address: address,
    phone: phone,
    contactName: contactName,
    isActive: isActive,
  );

  @override
  Future<void> setDebtLimit(String id, double? limit) =>
      _remote.setDebtLimit(id, limit);

  @override
  Future<void> setOwner(String id, String ownerPhone) =>
      _remote.setOwner(id, ownerPhone);

  @override
  Future<List<ShopPayment>> getPayments(String shopId) =>
      _remote.getPayments(shopId);

  @override
  Future<void> createPayment({
    required String shopId,
    String? orderId,
    required double amount,
    required PaymentMethod method,
  }) => _remote.createPayment(
    shopId: shopId,
    orderId: orderId,
    amount: amount,
    method: method,
  );

  @override
  Future<void> reversePayment(String id, String reason) =>
      _remote.reversePayment(id, reason);

  @override
  Future<List<ShopDebt>> getDebts() => _remote.getDebts();
}
