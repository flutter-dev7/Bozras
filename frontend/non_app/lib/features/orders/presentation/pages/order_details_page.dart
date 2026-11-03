import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:non_app/core/utils/launcher.dart';
import 'package:non_app/core/utils/navigation_launcher.dart';
import 'package:non_app/core/widgets/app_dialogs.dart';
import 'package:non_app/features/auth/domain/entities/user_role.dart';
import 'package:non_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:non_app/features/orders/domain/entities/order_draft.dart';
import 'package:non_app/features/orders/domain/entities/order_status.dart';
import 'package:non_app/features/orders/presentation/widgets/courier_action_button.dart';
import 'package:non_app/features/payments/presentation/widgets/collect_debt_card.dart';
import 'package:non_app/features/products/presentation/providers/products_providers.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../shops/presentation/providers/shops_providers.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_providers.dart';
import '../widgets/status_badge.dart';

class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context, WidgetRef ref, Order order) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Отменить заказ?',
      message: 'Заказ на ${Formatters.date(order.deliveryDate)} будет отменён.',
      confirmLabel: 'Отменить заказ',
      destructive: true,
    );

    if (!confirmed) return;

    try {
      await ref.read(cancelOrderUseCaseProvider)(order.id);

      ref.invalidate(orderDetailsProvider(order.id));
      ref.invalidate(ordersProvider);
      ref.invalidate(myBalanceProvider);

      if (context.mounted) {
        AppSnackBar.show(context, 'Заказ отменён');
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, e.message, isError: true);
      }
    }
  }

  Future<void> _repeat(BuildContext context, WidgetRef ref, Order order) async {
    try {
      final products = await ref.read(productsProvider.future);
      final byId = {for (final p in products) p.id: p};

      final lines = <String, OrderLine>{};

      for (final item in order.items) {
        final product = byId[item.productId];

        if (product == null) continue;

        lines[product.id] = OrderLine(
          productId: product.id,
          name: product.name,
          unitPrice: product.price,
          quantity: item.quantity,
        );
      }

      if (lines.isEmpty) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            'Этих товаров больше нет в каталоге',
            isError: true,
          );
        }
        return;
      }

      ref.read(cartProvider.notifier).replaceAll(lines);

      if (context.mounted) context.push(AppRoutes.orderForm);
    } catch (e) {
      if (context.mounted)
        AppSnackBar.show(context, errorText(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailsProvider(orderId));
    final role = ref.watch(
      authProvider.select((state) => state.valueOrNull?.role),
    );
    final isShop = role == UserRole.shop;
    final isCourier = role == UserRole.courier;
    final isAgent = role == UserRole.agent;

    return Scaffold(
      appBar: AppTopBar(
        title: order.valueOrNull == null
            ? 'Заказ'
            : 'Заказ №${order.value!.number}',
      ),
      body: order.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(orderDetailsProvider(orderId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _HeaderCard(order: data),
            const SizedBox(height: 16),
            if (data.status == OrderStatus.cancelled)
              const _CancelledBanner()
            else
              _TrackerCard(order: data),
            const SizedBox(height: 16),
            if (!isShop) ...[
              _ShopCard(order: data),
              const SizedBox(height: 16),
            ],
            _InfoCard(order: data),
            const SizedBox(height: 16),
            _ItemsCard(order: data),
            if (data.history.isNotEmpty) ...[
              const SizedBox(height: 16),
              _HistoryCard(order: data),
            ],
            if (isCourier && nextCourierStatus(data) != null) ...[
              const SizedBox(height: 20),
              CourierActionButton(order: data),
            ],
            if (isCourier) ...[
              const SizedBox(height: 16),
              CollectDebtCard(shopId: data.shopId, shopName: data.shopName),
            ],
            if ((isShop || (isAgent && data.source == 'Agent')) &&
                (data.canEdit || data.canCancel)) ...[
              const SizedBox(height: 20),
              if (data.canEdit)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.orderForm, extra: data),
                  icon: const Icon(AppIcons.edit, size: 20),
                  label: const Text('Изменить заказ'),
                ),
              if (data.canEdit && data.canCancel) const SizedBox(height: 12),
              if (data.canCancel)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => _cancel(context, ref, data),
                  child: const Text('Отменить заказ'),
                ),
            ],
            if (isShop) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _repeat(context, ref, data),
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text('Повторить заказ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppDecor.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Доставка',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: StatusBadge(status: order.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.date(order.deliveryDate),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Formatters.money(order.totalAmount),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _InfoRow(
            icon: AppIcons.wallet,
            label: 'Оплата',
            value: order.paymentType.label,
          ),
          const Divider(indent: 56),
          _InfoRow(
            icon: AppIcons.truck,
            label: 'Курьер',
            value: order.courierName ?? 'Пока не назначен',
          ),
          const Divider(indent: 56),
          _InfoRow(
            icon: AppIcons.calendar,
            label: 'Создан',
            value: Formatters.dateTime(order.createdAt),
          ),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const Divider(indent: 56),
            _InfoRow(
              icon: AppIcons.note,
              label: 'Комментарий',
              value: order.note!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppDecor.heroMid),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: AppColors.brown,
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Состав заказа',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${item.quantity} × ${Formatters.money(item.unitPrice)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.money(item.lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Text(
                  'Итого',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  Formatters.money(order.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (final entry in order.history)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: StatusBadge.colorOf(entry.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.status.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (entry.changedByName != null)
                            Text(
                              entry.changedByName!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.dateTime(entry.changedAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.shopName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.shopAddress,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.shopPhone,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: AppIcons.phone,
              tooltip: 'Позвонить',
              onPressed: () => callPhone(context, order.shopPhone),
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: Icons.directions_rounded,
              tooltip: 'Маршрут',
              onPressed: () => openRoute(
                context,
                latitude: order.shopLatitude,
                longitude: order.shopLongitude,
                address: order.shopAddress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.block, color: AppColors.error),
          SizedBox(width: 12),
          Text(
            'Заказ отменён',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.order});

  final Order order;

  static const _steps = [
    OrderStatus.created,
    OrderStatus.accepted,
    OrderStatus.baking,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];

  static const _icons = [
    Icons.inbox_outlined,
    Icons.fact_check_outlined,
    Icons.local_fire_department_outlined,
    Icons.local_shipping_outlined,
    Icons.inventory_2_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(order.status);
    final delivered = order.status == OrderStatus.delivered;
    final times = {for (final h in order.history) h.status: h.changedAt};

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _steps.length; i++)
              Expanded(
                child: _TrackerStep(
                  icon: _icons[i],
                  label: _steps[i].label,
                  time: times[_steps[i]],
                  done: delivered || i < current,
                  active: !delivered && i == current,
                  leftLit: i > 0 && (delivered || i <= current),
                  rightLit: i < _steps.length - 1 && (delivered || i < current),
                  isFirst: i == 0,
                  isLast: i == _steps.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.icon,
    required this.label,
    required this.time,
    required this.done,
    required this.active,
    required this.leftLit,
    required this.rightLit,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final DateTime? time;
  final bool done;
  final bool active;
  final bool leftLit;
  final bool rightLit;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final lit = done || active;

    Widget line(bool on, bool visible) => Expanded(
      child: Container(
        height: 3,
        color: !visible
            ? Colors.transparent
            : on
            ? AppDecor.heroMid
            : AppColors.border,
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              line(leftLit, !isFirst),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppDecor.heroMid : Colors.white,
                  border: Border.all(
                    color: lit ? AppDecor.heroMid : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppDecor.heroMid.withValues(alpha: 0.25),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  done ? Icons.check : icon,
                  size: 18,
                  color: done
                      ? Colors.white
                      : active
                      ? AppDecor.heroMid
                      : AppColors.muted,
                ),
              ),
              line(rightLit, !isLast),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: lit ? AppColors.brown : AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time == null ? ' ' : DateFormat('HH:mm').format(time!),
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
