import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../orders/domain/entities/payment_method.dart';
import '../../../shops/presentation/providers/shops_providers.dart';
import '../providers/payments_providers.dart';

class _DebtPayment {
  const _DebtPayment(this.amount, this.method);

  final double amount;
  final PaymentMethod method;
}

class CollectDebtCard extends ConsumerWidget {
  const CollectDebtCard({super.key, required this.shopId, required this.shopName});

  final String shopId;
  final String shopName;

  Future<void> _collect(BuildContext context, WidgetRef ref, double debt) async {
    final payment = await showModalBottomSheet<_DebtPayment>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _DebtSheet(shopName: shopName, debt: debt),
    );

    if (payment == null) return;

    try {
      await ref.read(paymentsRemoteProvider).createPayment(
            shopId: shopId,
            amount: payment.amount,
            method: payment.method,
          );

      ref.invalidate(shopBalanceProvider(shopId));

      if (context.mounted) {
        AppSnackBar.show(context, 'Оплата принята: ${Formatters.money(payment.amount)}');
      }
    } on ApiException catch (e) {
      if (context.mounted) AppSnackBar.show(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(shopBalanceProvider(shopId)).valueOrNull;

    if (balance == null || balance.debt <= 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(AppIcons.wallet, color: AppDecor.heroMid, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Долг магазина',
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.money(balance.debt),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => _collect(context, ref, balance.debt),
              child: const Text('Принять оплату'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtSheet extends StatefulWidget {
  const _DebtSheet({required this.shopName, required this.debt});

  final String shopName;
  final double debt;

  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  late final TextEditingController _amount;
  PaymentMethod _method = PaymentMethod.cash;
  String? _error;

  @override
  void initState() {
    super.initState();

    final debt = widget.debt;
    _amount = TextEditingController(
      text: debt == debt.roundToDouble() ? debt.toStringAsFixed(0) : debt.toString(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_amount.text.trim().replaceAll(',', '.'));

    if (value == null || value <= 0) {
      setState(() => _error = 'Введите сумму больше нуля');
      return;
    }

    if (value > widget.debt) {
      setState(() => _error = 'Не больше долга: ${Formatters.money(widget.debt)}');
      return;
    }

    Navigator.of(context).pop(_DebtPayment(value, _method));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Оплата долга',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.shopName} · долг ${Formatters.money(widget.debt)}',
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            decoration: InputDecoration(
              hintText: 'Сумма',
              suffixText: 'сом.',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<PaymentMethod>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppDecor.heroMid,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.brown,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            segments: [
              for (final method in PaymentMethod.values)
                ButtonSegment(value: method, label: Text(method.label)),
            ],
            selected: {_method},
            onSelectionChanged: (value) => setState(() => _method = value.first),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Принять оплату',
            icon: AppIcons.success,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}