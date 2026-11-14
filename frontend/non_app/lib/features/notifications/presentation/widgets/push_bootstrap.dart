import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:non_app/features/notifications/presentation/provider/inbox_provider.dart';
import 'package:non_app/features/notifications/presentation/provider/notifications_providers.dart';
import 'package:non_app/features/notifications/presentation/utils/open_order.dart';

import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../../../orders/presentation/providers/courier_providers.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../../shop_management/presentation/providers/shop_management_providers.dart';
import '../../../shops/presentation/providers/shops_providers.dart';
import '../../../supplier/presentation/providers/supplier_providers.dart';
import '../../data/services/push_service.dart';

const _shopRequestType = 'shop_request';

class PushBootstrap extends ConsumerStatefulWidget {
  const PushBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends ConsumerState<PushBootstrap> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await ref
          .read(pushServiceProvider)
          .start(
            onOpenOrder: _openOrder,
            onForeground: _onForeground,
            onOpened: (m) {
              ref.read(inboxProvider.notifier).add(m, read: true);

              if (m.data['type'] == _shopRequestType) _openShopRequests();
            },
          );
    } catch (e) {
      debugPrint('Push start failed: $e');
    }
  }

  void _openOrder(String orderId, String? supplierId) {
    if (!mounted) return;

    openOrder(
      ProviderScope.containerOf(context),
      GoRouter.of(context),
      orderId,
      supplierId: supplierId,
    );
  }

  void _openShopRequests() {
    if (!mounted) return;

    ref.read(homeTargetProvider.notifier).open(HomeTarget.shopRequests);
  }

  void _onForeground(RemoteMessage message) {
    if (!mounted) return;

    ref.invalidate(ordersProvider);
    ref.invalidate(orderDetailsProvider);
    ref.invalidate(courierTodayProvider);
    ref.invalidate(myBalanceProvider);
    ref.invalidate(shopRequestsProvider);
    ref.invalidate(shopsManageProvider);
    ref.read(inboxProvider.notifier).add(message);

    final notification = message.notification;

    if (notification == null) return;

    final orderId = PushService.orderIdOf(message);
    final isShopRequest = message.data['type'] == _shopRequestType;

    VoidCallback? open;

    if (orderId != null) {
      open = () => _openOrder(orderId, PushService.supplierIdOf(message));
    } else if (isShopRequest) {
      open = _openShopRequests;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.title != null)
                Text(
                  notification.title!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              if (notification.body != null) Text(notification.body!),
            ],
          ),
          action: open == null
              ? null
              : SnackBarAction(label: 'Открыть', onPressed: open),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}