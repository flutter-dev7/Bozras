import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:non_app/core/router/app_routes.dart';
import 'package:non_app/core/utils/launcher.dart';
import 'package:non_app/features/shops/domain/entities/shop.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../orders/domain/entities/payment_method.dart';
import '../../domain/entities/managed_shop.dart';
import '../../domain/entities/shop_balance.dart';
import '../../domain/entities/shop_payment.dart';
import '../providers/shop_management_providers.dart';
import '../utils/phone.dart';
import 'shop_edit_page.dart';

String _methodLabel(PaymentMethod method) =>
    method.apiName == 'Cash' ? 'Наличные' : 'Перевод';

class ShopDetailsPage extends ConsumerWidget {
  const ShopDetailsPage({super.key, required this.shopId});

  final String shopId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(managedShopProvider(shopId));
    ref.invalidate(shopBalanceProvider(shopId));
    ref.invalidate(shopPaymentsProvider(shopId));
    ref.invalidate(shopsManageProvider);
    ref.invalidate(shopDebtsProvider);
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    String message,
    Future<void> Function() action,
  ) async {
    try {
      await action();

      _refresh(ref);

      if (context.mounted) AppSnackBar.show(context, message);
    } on ApiException catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, e.message, isError: true);
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ManagedShop shop,
  ) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ShopEditPage(shop: shop)));

    if (saved == true) {
      _refresh(ref);

      if (context.mounted) AppSnackBar.show(context, 'Данные сохранены');
    }
  }

  void _createOrder(BuildContext context, ManagedShop shop) {
    context.push(
      AppRoutes.orderForm,
      extra: Shop(
        id: shop.id,
        name: shop.name,
        address: shop.address,
        phone: shop.phone,
        contactName: shop.contactName,
        debtLimit: shop.debtLimit,
        isActive: shop.isActive,
        latitude: shop.latitude,
        longitude: shop.longitude,
      ),
    );
  }

  Future<void> _acceptPayment(
    BuildContext context,
    WidgetRef ref,
    ShopBalance balance,
  ) async {
    final input = await showDialog<_PaymentInput>(
      context: context,
      builder: (_) => _PaymentDialog(balance: balance),
    );

    if (input == null || !context.mounted) return;

    await _run(
      context,
      ref,
      'Оплата принята',
      () => ref.read(createShopPaymentUseCaseProvider)(
        shopId: shopId,
        orderId: input.orderId,
        amount: input.amount,
        method: input.method,
      ),
    );
  }

  Future<void> _setLimit(
    BuildContext context,
    WidgetRef ref,
    ManagedShop shop,
  ) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: 'Лимит долга',
        label: 'Сумма, сом.',
        hint: 'Пусто — без ограничения',
        initial: shop.debtLimit == null
            ? ''
            : shop.debtLimit!.toStringAsFixed(0),
        allowEmpty: true,
        numeric: true,
      ),
    );

    if (text == null || !context.mounted) return;

    final limit = text.isEmpty
        ? null
        : double.tryParse(text.replaceAll(',', '.'));

    if (text.isNotEmpty && (limit == null || limit < 0)) {
      AppSnackBar.show(context, 'Введите корректный лимит', isError: true);
      return;
    }

    await _run(
      context,
      ref,
      'Лимит долга сохранён',
      () => ref.read(setDebtLimitUseCaseProvider)(shopId, limit),
    );
  }

  Future<void> _setOwner(BuildContext context, WidgetRef ref) async {
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => const _TextDialog(
        title: 'Владелец магазина',
        label: 'Телефон пользователя',
        phone: true,
      ),
    );

    if (phone == null || !context.mounted) return;

    await _run(
      context,
      ref,
      'Владелец привязан',
      () => ref.read(setShopOwnerUseCaseProvider)(shopId, toApiPhone(phone)),
    );
  }

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    ShopPayment payment,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) =>
          const _TextDialog(title: 'Отменить оплату', label: 'Причина отмены'),
    );

    if (reason == null || !context.mounted) return;

    await _run(
      context,
      ref,
      'Оплата отменена',
      () => ref.read(reverseShopPaymentUseCaseProvider)(payment.id, reason),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(managedShopProvider(shopId));
    final balanceAsync = ref.watch(shopBalanceProvider(shopId));
    final paymentsAsync = ref.watch(shopPaymentsProvider(shopId));

    return Scaffold(
      appBar: AppTopBar(title: shopAsync.valueOrNull?.name ?? 'Магазин'),
      body: Builder(
        builder: (context) {
          final error = shopAsync.error ?? balanceAsync.error;

          if (error != null) {
            return ErrorView(
              message: errorText(error),
              onRetry: () => _refresh(ref),
            );
          }

          final shop = shopAsync.valueOrNull;
          final balance = balanceAsync.valueOrNull;

          if (shop == null || balance == null) return const LoadingView();

          return RefreshIndicator(
            onRefresh: () async {
              _refresh(ref);
              await ref.read(shopBalanceProvider(shopId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _HeaderCard(shop: shop),
                const SizedBox(height: 16),
                _StatsGrid(balance: balance),
                if (balance.isOverLimit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Долг превышает установленный лимит',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppDecor.heroMid,
                  ),
                  onPressed: () => _acceptPayment(context, ref, balance),
                  icon: const Icon(AppIcons.wallet, size: 20),
                  label: Text(
                    balance.debt > 0
                        ? 'Принять оплату (долг ${Formatters.money(balance.debt)})'
                        : 'Принять оплату',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: shop.isActive
                      ? () => _createOrder(context, shop)
                      : null,
                  icon: const Icon(AppIcons.plus, size: 20),
                  label: const Text('Создать заказ'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setLimit(context, ref, shop),
                        child: const Text('Лимит долга'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _edit(context, ref, shop),
                        child: const Text('Изменить данные'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppDecor.heroMid,
                    ),
                    title: const Text(
                      'Владелец магазина',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      shop.ownerName == null
                          ? 'Не привязан'
                          : '${shop.ownerName} · ${shop.ownerPhone ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brown,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _setOwner(context, ref),
                      child: const Text('Привязать'),
                    ),
                  ),
                ),
                if (balance.unpaidOrders.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Неоплаченные заказы',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          for (final order in balance.unpaidOrders)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Formatters.date(order.deliveryDate),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'оплачено ${Formatters.money(order.paidAmount)} из ${Formatters.money(order.totalAmount)}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Formatters.money(order.remainingAmount),
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'История оплат',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                paymentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(errorText(e)),
                  data: (payments) => payments.isEmpty
                      ? const Text(
                          'Оплат пока нет',
                          style: TextStyle(color: AppColors.muted),
                        )
                      : Column(
                          children: [
                            for (final payment in payments)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PaymentTile(
                                  payment: payment,
                                  onReverse: () =>
                                      _reverse(context, ref, payment),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.shop});

  final ManagedShop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppDecor.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shop.address,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 4),
                Text(
                  shop.phone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (shop.contactName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    shop.contactName!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                if (!shop.isActive) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Отключён',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppIconButton(
            icon: AppIcons.phone,
            tooltip: 'Позвонить',
            onPressed: () => callPhone(context, shop.phone),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.balance});

  final ShopBalance balance;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, {Color? color}) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: [
        stat(
          'Долг',
          Formatters.money(balance.debt),
          color: balance.debt > 0 ? AppColors.error : null,
        ),
        stat('Доставлено', Formatters.money(balance.deliveredTotal)),
        stat('Оплачено', Formatters.money(balance.paidTotal)),
        stat(
          'Лимит долга',
          balance.debtLimit == null
              ? 'Нет'
              : Formatters.money(balance.debtLimit!),
          color: balance.isOverLimit ? AppColors.error : null,
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onReverse});

  final ShopPayment payment;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final sign = payment.isReversal ? '−' : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$sign${Formatters.money(payment.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: payment.isReversal ? AppColors.error : null,
                        ),
                      ),
                      if (payment.isReversal)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      if (payment.isReversed)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Отменён',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.dateTime(payment.createdAt)} · ${_methodLabel(payment.method)}'
                    '${payment.receivedByName != null ? ' · ${payment.receivedByName}' : ''}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  if (payment.reversalReason != null)
                    Text(
                      'Причина: ${payment.reversalReason}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
            if (payment.canReverse)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: onReverse,
                child: const Text('Отменить'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentInput {
  const _PaymentInput(this.amount, this.method, this.orderId);

  final double amount;
  final PaymentMethod method;
  final String? orderId;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.balance});

  final ShopBalance balance;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amount = TextEditingController();
  late PaymentMethod _method;
  String? _orderId;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      setState(() => _error = 'Введите сумму');
      return;
    }

    Navigator.of(context).pop(_PaymentInput(value, _method, _orderId));
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = widget.balance.unpaidOrders;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Принять оплату',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Сумма',
                errorText: _error,
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PaymentMethod>(
                showSelectedIcon: false,
                segments: [
                  for (final method in PaymentMethod.values)
                    ButtonSegment(
                      value: method,
                      label: Text(_methodLabel(method)),
                    ),
                ],
                selected: {_method},
                onSelectionChanged: (v) => setState(() => _method = v.first),
              ),
            ),
            if (unpaid.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                value: _orderId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Заказ'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Без привязки к заказу'),
                  ),
                  for (final o in unpaid)
                    DropdownMenuItem(
                      value: o.orderId,
                      child: Text(
                        '${Formatters.date(o.deliveryDate)} — ${Formatters.money(o.remainingAmount)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _orderId = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: _done,
          child: const Text('Принять'),
        ),
      ],
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    this.hint,
    this.initial = '',
    this.allowEmpty = false,
    this.numeric = false,
    this.phone = false,
  });

  final String title;
  final String label;
  final String? hint;
  final String initial;
  final bool allowEmpty;
  final bool numeric;
  final bool phone;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    final text = _controller.text.trim();

    if (text.isEmpty && !widget.allowEmpty) return;

    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.phone
            ? TextInputType.phone
            : widget.numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: _done,
          child: const Text('Готово'),
        ),
      ],
    );
  }
}
