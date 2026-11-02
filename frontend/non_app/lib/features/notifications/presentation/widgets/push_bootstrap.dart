import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:non_app/features/notifications/presentation/provider/notifications_providers.dart';

import '../../../../core/router/app_routes.dart';
import '../../../orders/presentation/providers/courier_providers.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../../shops/presentation/providers/shops_providers.dart';
import '../../data/services/push_service.dart';

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
      await ref.read(pushServiceProvider).start(
            onOpenOrder: _openOrder,
            onForeground: _onForeground,
          );
    } catch (e) {
      debugPrint('Push start failed: $e');
    }
  }

  void _openOrder(String orderId) {
    if (!mounted) return;

    context.push(AppRoutes.orderDetailsFor(orderId));
  }

  void _onForeground(RemoteMessage message) {
    if (!mounted) return;

    ref.invalidate(ordersProvider);
    ref.invalidate(orderDetailsProvider);
    ref.invalidate(courierTodayProvider);
    ref.invalidate(myBalanceProvider);

    final notification = message.notification;

    if (notification == null) return;

    final orderId = PushService.orderIdOf(message);

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
          action: orderId == null
              ? null
              : SnackBarAction(label: 'Открыть', onPressed: () => _openOrder(orderId)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}