import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/core/widgets/app_dialogs.dart';
import 'package:non_app/features/products/presentation/providers/products_providers.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/courier.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_type.dart';
import '../providers/orders_providers.dart';

OrderStatus? _nextOf(OrderStatus status) => switch (status) {
  OrderStatus.created => OrderStatus.accepted,
  OrderStatus.accepted => OrderStatus.baking,
  OrderStatus.baking => OrderStatus.onTheWay,
  OrderStatus.onTheWay => OrderStatus.delivered,
  _ => null,
};

String _labelOf(OrderStatus status) => switch (status) {
  OrderStatus.created => 'Принять заказ',
  OrderStatus.accepted => 'Начать готовку',
  OrderStatus.baking => 'Отправить в путь',
  OrderStatus.onTheWay => 'Отметить доставленным',
  _ => '',
};

String _hintOf(OrderStatus status) => switch (status) {
  OrderStatus.created => 'Подтвердите заказ, чтобы он пошёл в работу.',
  OrderStatus.accepted => 'Передайте заказ на готовку.',
  OrderStatus.baking =>
    'Когда хлеб готов, отправьте заказ курьеру. Для этого должен быть назначен курьер.',
  OrderStatus.onTheWay =>
    'После передачи хлеба магазину отметьте заказ доставленным.',
  _ => '',
};

String _methodLabel(PaymentMethod method) =>
    method.apiName == 'Cash' ? 'Наличные' : 'Перевод';

class AdminOrderActions extends ConsumerStatefulWidget {
  const AdminOrderActions({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<AdminOrderActions> createState() => _AdminOrderActionsState();
}

class _AdminOrderActionsState extends ConsumerState<AdminOrderActions> {
  bool _busy = false;

  Order get _order => widget.order;

  bool get _isFinal =>
      _order.status == OrderStatus.delivered ||
      _order.status == OrderStatus.cancelled;

  bool get _tooEarly {
    final next = _nextOf(_order.status);

    if (next != OrderStatus.onTheWay && next != OrderStatus.delivered) {
      return false;
    }

    final today = Formatters.today();
    final delivery = _order.deliveryDate;

    return DateTime(delivery.year, delivery.month, delivery.day).isAfter(
      DateTime(today.year, today.month, today.day),
    );
  }

  Future<void> _run(String message, Future<void> Function() action) async {
    setState(() => _busy = true);

    try {
      await action();

      ref.invalidate(orderDetailsProvider(_order.id));
      ref.invalidate(ordersProvider);
      ref.invalidate(productsProvider);

      if (mounted) AppSnackBar.show(context, message);
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    final next = _nextOf(_order.status);

    if (next == null) return;

    double? amount;
    PaymentMethod? method;

    if (next == OrderStatus.delivered && _order.paymentType == PaymentType.now) {
      final result = await showDialog<_PaymentResult>(
        context: context,
        builder: (_) => _PaymentDialog(initial: _order.totalAmount),
      );

      if (result == null) return;

      amount = result.amount;
      method = result.method;
    }

    await _run(
      'Статус: ${next.label}',
      () => ref
          .read(ordersRepositoryProvider)
          .changeStatus(
            _order.id,
            next,
            paymentAmount: amount,
            paymentMethod: method,
          ),
    );
  }

  Future<void> _cancel() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Отменить заказ?',
      message:
          'Заказ на ${Formatters.date(_order.deliveryDate)} будет отменён.',
      confirmLabel: 'Отменить заказ',
      destructive: true,
    );

    if (!confirmed) return;

    await _run(
      'Заказ отменён',
      () => ref.read(cancelOrderUseCaseProvider)(_order.id),
    );
  }

  Future<void> _pickCourier() async {
    final courier = await showModalBottomSheet<Courier>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _CourierSheet(currentId: _order.courierId),
    );

    if (courier == null) return;

    await _run(
      'Курьер назначен: ${courier.name}',
      () => ref.read(assignCourierUseCaseProvider)(_order.id, courier.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinal) return const SizedBox.shrink();

    final next = _nextOf(_order.status);
    final needsCourier =
        next == OrderStatus.onTheWay && _order.courierId == null;
    final tooEarly = _tooEarly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Следующий шаг',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (next != null)
                  Text(
                    _hintOf(_order.status),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                const SizedBox(height: 14),
                if (next != null)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppDecor.heroMid,
                    ),
                    onPressed: _busy || needsCourier || tooEarly ? null : _next,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(_labelOf(_order.status)),
                  ),
                if (needsCourier) ...[
                  const SizedBox(height: 10),
                  const _Notice(
                    'Сначала назначьте курьера в блоке «Курьер» ниже.',
                  ),
                ],
                if (tooEarly) ...[
                  const SizedBox(height: 10),
                  _Notice(
                    'Доставка запланирована на ${Formatters.date(_order.deliveryDate)}. '
                    'Отправить в путь или отметить доставленным можно только в этот день.',
                  ),
                ],
                if (_order.paymentType == PaymentType.debt &&
                    _order.status == OrderStatus.onTheWay) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Заказ в долг: после доставки сумма добавится к долгу магазина.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Курьер',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      _order.courierId == null ? 'Не назначен' : 'Назначен',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _order.courierId == null
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                if (_order.courierName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _order.courierName!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickCourier,
                  icon: const Icon(AppIcons.truck, size: 20),
                  label: Text(
                    _order.courierId == null
                        ? 'Назначить курьера'
                        : 'Заменить курьера',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_order.canCancel) ...[
          const SizedBox(height: 12),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _busy ? null : _cancel,
            child: const Text('Отменить заказ'),
          ),
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
      ),
    );
  }
}

class _CourierSheet extends ConsumerWidget {
  const _CourierSheet({required this.currentId});

  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couriers = ref.watch(couriersProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: couriers.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text(errorText(error))),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Нет активных курьеров.\nДобавьте их в разделе «Пользователи» в вебе.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final courier = list[index];
                final current = courier.id == currentId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !current,
                  title: Text(
                    courier.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(courier.phone),
                  trailing: current
                      ? const Icon(Icons.check, color: AppDecor.heroMid)
                      : const Text(
                          'Назначить',
                          style: TextStyle(
                            color: AppDecor.heroMid,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  onTap: current
                      ? null
                      : () => Navigator.of(context).pop(courier),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PaymentResult {
  const _PaymentResult(this.amount, this.method);

  final double amount;
  final PaymentMethod method;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.initial});

  final double initial;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amount;
  late PaymentMethod _method;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.initial.toStringAsFixed(0));
    _method = PaymentMethod.values.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _done() {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));

    if (value == null || value <= 0) {
      setState(() => _error = 'Введите сумму оплаты');
      return;
    }

    Navigator.of(context).pop(_PaymentResult(value, _method));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Оплата при доставке',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(labelText: 'Сумма', errorText: _error),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 16),
          SegmentedButton<PaymentMethod>(
            showSelectedIcon: false,
            segments: [
              for (final method in PaymentMethod.values)
                ButtonSegment(value: method, label: Text(_methodLabel(method))),
            ],
            selected: {_method},
            onSelectionChanged: (value) =>
                setState(() => _method = value.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: _done,
          child: const Text('Подтвердить'),
        ),
      ],
    );
  }
}