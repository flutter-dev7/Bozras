import 'package:non_app/features/shop_management/domain/entities/shop_debt.dart';

import '../../../../core/models/paged_result.dart';
import '../../../orders/domain/entities/payment_method.dart';
import '../entities/managed_shop.dart';
import '../entities/shop_balance.dart';
import '../entities/shop_payment.dart';

abstract class ShopManagementRepository {
  Future<PagedResult<ManagedShop>> getShops({
    String? search,
    bool? isActive,
    required int page,
    required int pageSize,
  });

  Future<ManagedShop> getShop(String id);

  Future<ShopBalance> getBalance(String id);

  Future<void> updateShop(
    String id, {
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required bool isActive,
  });

  Future<void> setDebtLimit(String id, double? limit);

  Future<void> setOwner(String id, String ownerPhone);

  Future<List<ShopPayment>> getPayments(String shopId);

  Future<void> createPayment({
    required String shopId,
    String? orderId,
    required double amount,
    required PaymentMethod method,
  });

  Future<void> reversePayment(String id, String reason);

  Future<List<ShopDebt>> getDebts();
}
