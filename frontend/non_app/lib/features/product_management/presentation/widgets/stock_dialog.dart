import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../domain/entities/managed_product.dart';
import '../providers/product_management_providers.dart';

Future<void> showStockDialog(BuildContext context, ManagedProduct product) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StockDialog(product: product),
  );
}

class _StockDialog extends ConsumerStatefulWidget {
  const _StockDialog({required this.product});

  final ManagedProduct product;

  @override
  ConsumerState<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends ConsumerState<_StockDialog> {
  final _quantity = TextEditingController();
  final _comment = TextEditingController();
  bool _receipt = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantity.text.trim());
    final comment = _comment.text.trim();

    if (quantity == null || quantity < 1) {
      setState(() => _error = 'Введите количество — целое число от 1');
      return;
    }

    if (!_receipt && comment.isEmpty) {
      setState(() => _error = 'Укажите причину списания');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_receipt) {
        await ref.read(receiveStockUseCaseProvider)(
          widget.product.id,
          quantity,
          comment.isEmpty ? null : comment,
        );
      } else {
        await ref.read(writeOffStockUseCaseProvider)(
          widget.product.id,
          quantity,
          comment,
        );
      }

      ref.invalidate(productsManageProvider);

      if (!mounted) return;

      Navigator.of(context).pop();
      AppSnackBar.show(context, _receipt ? 'Товар принят на склад' : 'Списано');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('На складе: ${product.stockQuantity} ${product.unit}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Приход')),
                  ButtonSegment(value: false, label: Text('Списание')),
                ],
                selected: {_receipt},
                onSelectionChanged: _busy
                    ? null
                    : (v) => setState(() => _receipt = v.first),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              autofocus: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Количество, ${product.unit}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              enabled: !_busy,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: _receipt
                    ? 'Комментарий (необязательно)'
                    : 'Причина списания',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: _busy ? null : _submit,
          child: Text(_receipt ? 'Принять' : 'Списать'),
        ),
      ],
    );
  }
}