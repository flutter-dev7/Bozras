import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_icons.dart';
import '../theme/app_decor.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10000,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  Future<void> _askValue(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityDialog(initial: value),
    );

    if (result != null) {
      onChanged(result.clamp(min, max));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: AppIcons.minus,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _askValue(context),
          child: Container(
            constraints: const BoxConstraints(minWidth: 56),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppDecor.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppDecor.heroMid.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundButton(
          icon: AppIcons.plus,
          enabled: value < max,
          filled: true,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppDecor.heroMid
        : AppDecor.heroMid.withValues(alpha: 0.3);

    return Material(
      color: filled ? color : Colors.transparent,
      shape: CircleBorder(
        side: filled ? BorderSide.none : BorderSide(color: color, width: 1.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: filled ? Colors.white : color),
        ),
      ),
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.initial});

  final int initial;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initial}');
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() => Navigator.of(context).pop(int.tryParse(_controller.text));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Количество',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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
