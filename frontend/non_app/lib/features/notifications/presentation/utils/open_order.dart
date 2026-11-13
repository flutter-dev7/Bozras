import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../connections/presentation/providers/connections_providers.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../../../shops/presentation/providers/shops_providers.dart';

Future<void> openOrder(
  ProviderContainer container,
  GoRouter router,
  String orderId, {
  String? supplierId,
}) async {
  final isShop = container.read(authProvider).valueOrNull?.role == UserRole.shop;

  if (isShop &&
      supplierId != null &&
      supplierId != container.read(currentSupplierIdProvider)) {
    await container.read(shopGateProvider.notifier).select(supplierId);

    container.invalidate(productsProvider);
    container.invalidate(ordersProvider);
    container.invalidate(orderDetailsProvider);
    container.invalidate(myBalanceProvider);
  }

  router.push(AppRoutes.orderDetailsFor(orderId));
}