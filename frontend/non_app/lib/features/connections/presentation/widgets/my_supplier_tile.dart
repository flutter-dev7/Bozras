import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/my_supplier.dart';

class MySupplierTile extends StatelessWidget {
  const MySupplierTile({
    super.key,
    required this.supplier,
    required this.selected,
    required this.onTap,
  });

  final MySupplier supplier;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final note = switch (supplier.status) {
      ConnectionStatus.pending => 'Ожидает подтверждения',
      ConnectionStatus.rejected => 'Заявка отклонена',
      ConnectionStatus.active => supplier.isAvailable ? null : 'Временно недоступен',
    };

    return Card(
      child: ListTile(
        enabled: onTap != null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: const Icon(AppIcons.store),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: note == null
            ? null
            : Text(note, style: const TextStyle(color: AppColors.muted)),
        trailing: selected ? const Icon(AppIcons.success, color: AppColors.success) : null,
        onTap: onTap,
      ),
    );
  }
}