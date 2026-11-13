import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/supplier_card.dart';

class SupplierCardTile extends StatelessWidget {
  const SupplierCardTile({
    super.key,
    required this.supplier,
    required this.busy,
    required this.onConnect,
  });

  final SupplierCard supplier;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final label = switch (supplier.status) {
      ConnectionStatus.active => 'Подключён',
      ConnectionStatus.pending => 'Ожидает',
      ConnectionStatus.rejected => 'Отклонено',
      null => null,
    };

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
                    supplier.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  if (supplier.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      supplier.description!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (supplier.requiresApproval) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Нужно подтверждение поставщика',
                      style: TextStyle(
                        color: AppDecor.heroMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (label != null)
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800))
            else
              FilledButton(
                onPressed: busy ? null : onConnect,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Подключиться'),
              ),
          ],
        ),
      ),
    );
  }
}